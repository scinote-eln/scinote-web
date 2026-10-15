# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MyModuleReports::GenerateReportService do
  include_context 'docx_report'

  let(:template_path) { Rails.root.join('app/assets/report_templates/odt_A4_portrait_watermark_template.odt') }
  let(:report_template) do
    ReportTemplate.create!(subject: my_module, name: 'Template').tap do |template|
      template.odt_template_file.attach(io: File.open(template_path), filename: 'my template.odt',
                                        content_type: 'application/vnd.oasis.opendocument.text')
    end
  end
  let(:analytical_report) do
    AnalyticalReport.create!(name: 'Analytical', generating_status: :in_progress, reference: my_module,
                             created_by: user, report_template: report_template)
  end
  let(:service) { described_class.new(my_module.protocol, report_template, team, user) }
  let(:calls) { Hash.new { |hash, key| hash[key] = [] } }

  # Lets the real ODFReport do its work while recording what the service feeds into it
  before do
    user.update!(current_team_id: team.id)
    %i(add_field add_text add_table_from_data add_checklist add_inline_image).each do |meth|
      allow_any_instance_of(ODFReport::Report).to receive(meth).and_wrap_original do |original, *args, **opts, &block|
        calls[meth] << (opts.empty? ? args : args + [opts])
        original.call(*args, **opts, &block)
      end
    end
  end

  def tag(type, id)
    I18n.t('protocols.report_template.data_inputs.codes.tag_content',
           content_type: I18n.t("protocols.report_template.data_inputs.codes.type.#{type}"), id: id)
  end

  def fields
    calls[:add_field].to_h { |name, value| [name.to_s, value] }
  end

  def texts_for(name)
    calls[:add_text].select { |args| args.first.to_s == name.to_s }.map { |args| args[1] }
  end

  def generate
    service.call(analytical_report)
  end

  # Private temp dir per example, so the service's output file is the only thing that can show up in it
  def with_private_tmpdir
    dir = Dir.mktmpdir('report_service_spec')
    allow(Dir).to receive(:tmpdir).and_return(dir)
    yield dir
  ensure
    # other hooks (shared contexts) create tempfiles later and need the real tmp dir again
    allow(Dir).to receive(:tmpdir).and_call_original
    FileUtils.remove_entry(dir) if dir && File.exist?(dir)
  end

  describe '#call' do
    it 'attaches the generated odt to the analytical report under the template file name and type' do
      generate

      attached = analytical_report.reload.report
      expect(attached).to be_attached
      expect(attached.filename.to_s).to eq 'my template.odt'
      expect(attached.content_type).to eq 'application/vnd.oasis.opendocument.text'
      zip_entries = []
      Zip::File.open_buffer(StringIO.new(attached.download)) { |zip| zip_entries = zip.map(&:name) }
      expect(zip_entries).to include('content.xml', 'mimetype')
    end

    it 'does not leave the generated file behind' do
      with_private_tmpdir do |dir|
        generate
        expect(Dir).to have_received(:tmpdir).at_least(:once)
        expect(Dir[File.join(dir, 'report*.odt')]).to be_empty
        expect(analytical_report.reload.report).to be_attached
      end
    end

    it 'closes and removes the temporary output even when generation fails' do
      allow_any_instance_of(ODFReport::Report).to receive(:generate).and_raise(StandardError, 'odt broke')
      with_private_tmpdir do |dir|
        expect { generate }.to raise_error(StandardError, 'odt broke')
        expect(Dir).to have_received(:tmpdir).at_least(:once)
        expect(Dir[File.join(dir, 'report*.odt')]).to be_empty
      end
      expect(analytical_report.reload.report).not_to be_attached
    end
  end

  describe 'general task fields' do
    it 'fills the task name, an empty due date and tags in id order' do
      my_module.update!(name: 'Cloning task', due_date: nil)
      [['b-tag', '#111111'], ['a-tag', '#222222']].each do |name, color|
        Tagging.create!(tag: create(:tag, team: team, name: name, color: color), taggable: my_module, created_by: user)
      end

      generate

      expect(fields['TASKNAME']).to eq 'Cloning task'
      expect(fields['TASKDUEDATE']).to eq ''
      expect(texts_for(:TASKTAGS)).to eq ['<p>b-tag, a-tag</p>']
    end

    it 'formats the due date' do
      due = 3.days.from_now.change(usec: 0)
      my_module.update!(due_date: due)

      generate

      expect(fields['TASKDUEDATE']).to eq I18n.l(my_module.reload.due_date, format: :full)
    end
  end

  describe 'steps' do
    let!(:step_one) { add_step(name: 'Prepare', position: 0) }
    let!(:step_two) { add_step(name: 'Run', position: 1) }

    it 'adds a field per active step in order, resetting the full protocol tag after each step' do
      add_step(name: 'Hidden', position: 2).update!(archived: true, archived_on: Time.current)

      generate

      step_fields = calls[:add_field].map { |args| args.first.to_s }
      archived_step = my_module.protocol.steps.find_by(archived: true)
      expect(step_fields).to include(tag('step', step_one.id), tag('step', step_two.id))
      expect(step_fields).not_to include(tag('step', archived_step.id))
      expect(fields[tag('step', step_one.id)]).to eq 'Prepare'
      expect(calls[:add_field].count { |name, value| name == :PROTOCOL && value == '' }).to eq 2
    end

    it 'adds the numbered step name to the full protocol text' do
      generate
      expect(texts_for(:PROTOCOL)).to include("<div>1. Prepare</div><div>{{PROTOCOL}}</div>",
                                              "<div>2. Run</div><div>{{PROTOCOL}}</div>")
    end

    context 'with a text element' do
      let(:step_text) do
        create(:step_text, step: step_one, name: 'Notes', text: '<p>Mix <b>well</b></p>')
      end

      before { add_step_element(step_one, step_text, 0) }

      it 'adds the text under its own tag and in the protocol text' do
        generate
        text_tag = tag('step_text', step_text.id)

        expect(texts_for(text_tag)).to eq ["<div>Notes</div><div>{{#{text_tag}}}</div>",
                                           '<p>Mix <b>well</b></p>']
        expect(texts_for(:PROTOCOL)).to include("<div>Notes</div><div>{{PROTOCOL}}</div>",
                                                '<div><p>Mix <b>well</b></p></div><div>{{PROTOCOL}}</div>')
      end

      it 'skips archived elements' do
        step_text.update_columns(archived: true)
        generate
        expect(texts_for(tag('step_text', step_text.id))).to be_empty
        expect(texts_for(:PROTOCOL).join).not_to include('Notes')
      end
    end

    context 'with a table element' do
      let(:table) { create :table, name: 'Grid', contents: { data: [%w(A B), %w(C D)] }.to_json }

      before { add_step_element(step_one, create(:step_table, step: step_one, table: table), 0) }

      it 'adds the table data with its name for the table tag and the protocol' do
        generate
        table_tag = tag('step_table', table.id)

        expect(texts_for(table_tag)).to eq ["<div>Grid</div><div>{{#{table_tag}}}</div>"]
        expect(texts_for(:PROTOCOL)).to include("<div>Grid</div><div>{{PROTOCOL_TABLE_#{table_tag}}}</div><div>{{PROTOCOL}}</div>")
        names_and_data = calls[:add_table_from_data].map { |name, data| [name.to_s, data[:table_name], data[:contents]] }
        expect(names_and_data).to eq [[table_tag, 'Grid', [%w(A B), %w(C D)]],
                                      ["PROTOCOL_TABLE_#{table_tag}", 'Grid', [%w(A B), %w(C D)]]]
      end
    end

    context 'with a checklist element' do
      let!(:checklist) { create :checklist, step: step_one, name: 'To do' }

      before do
        create :checklist_item, checklist: checklist, text: 'one', checked: true, position: 0
        create :checklist_item, checklist: checklist, text: 'two', checked: false, position: 1
        add_step_element(step_one, checklist, 0)
      end

      it 'adds the checklist items with checked flags under its tag and the protocol checklist tag' do
        generate
        checklist_tag = tag('checklist', checklist.id)

        expect(texts_for(checklist_tag)).to eq ["<div>To do</div><div>{{#{checklist_tag}}}</div>"]
        expect(texts_for(:PROTOCOL)).to include("<div>To do</div><div>{{PROTOCOL_CHECKLIST}}</div><div>{{PROTOCOL}}</div>")
        pairs = calls[:add_checklist].map { |name, items, opts| [name.to_s, items.sort, opts] }
        expected_items = [['one', true], ['two', false]]
        expect(pairs).to eq [[checklist_tag, expected_items, { checked_symbol: "⊠" }],
                             ['PROTOCOL_CHECKLIST', expected_items, { checked_symbol: "⊠" }]]
      end
    end

    context 'with a form response' do
      let(:submitter) { create :user, full_name: 'Form Submitter' }
      let(:form) { create :form, team: team, created_by: user, last_modified_by: user, name: 'Quality form' }
      let(:form_response) do
        create :form_response, :submitted, form: form, created_by: user, submitted_by: submitter, parent: step_one,
                                           step_orderable_element: nil
      end
      let(:repository) { create :repository, team: team, created_by: user }
      let(:repository_row) { create :repository_row, repository: repository, created_by: user, name: 'Row X' }
      let!(:text_field) { create :form_field, form: form, created_by: user, position: 0, data: { type: 'TextField' } }
      let!(:date_field) do
        create :form_field, form: form, created_by: user, position: 1, data: { type: 'DatetimeField', time: false }
      end
      let!(:rows_field) { create :form_field, form: form, created_by: user, position: 2, data: { type: 'RepositoryRowsField' } }
      let!(:multi_field) do
        create :form_field, form: form, created_by: user, position: 3,
                            data: { type: 'MultipleChoiceField', options: %w(red green blue) }
      end
      let!(:single_field) do
        create :form_field, form: form, created_by: user, position: 4,
                            data: { type: 'SingleChoiceField', options: %w(yes no) }
      end
      let!(:number_field) do
        create :form_field, form: form, created_by: user, position: 5, data: { type: 'NumberField', unit: 'kg' }
      end
      let!(:na_field) { create :form_field, form: form, created_by: user, position: 6, data: { type: 'TextField' } }
      let!(:na_choice_field) do
        create :form_field, form: form, created_by: user, position: 7,
                            data: { type: 'SingleChoiceField', options: %w(a b) }
      end
      let!(:unanswered_multi) do
        create :form_field, form: form, created_by: user, position: 8,
                            data: { type: 'MultipleChoiceField', options: %w(x y) }
      end

      def form_tag(field)
        I18n.t('protocols.report_template.data_inputs.codes.tag_form_field', form_id: form_response.id, id: field.id)
      end

      before do
        add_step_element(step_one, form_response, 0)
        form_response.create_value!(submitter, text_field, 'answer text')
        form_response.create_value!(submitter, date_field, '2024-03-05')
        form_response.create_value!(submitter, rows_field, [repository_row.id])
        form_response.create_value!(submitter, multi_field, %w(red blue))
        form_response.create_value!(submitter, single_field, 'no')
        form_response.create_value!(submitter, number_field, 12)
        form_response.create_value!(submitter, na_field, nil, not_applicable: true)
        form_response.create_value!(submitter, na_choice_field, nil, not_applicable: true)
        generate
      end

      it 'adds the form name under the form tag and in the protocol text' do
        expect(fields[tag('form_response', form_response.id)]).to eq 'Quality form'
        expect(texts_for(:PROTOCOL)).to include('<div>Quality form</div><div>{{PROTOCOL}}</div>')
      end

      it 'adds text answers' do
        expect(fields[form_tag(text_field)]).to eq 'answer text'
        expect(texts_for(:PROTOCOL)).to include('<div>answer text</div><div>{{PROTOCOL}}</div>')
      end

      it 'adds localized datetime answers' do
        expect(fields[form_tag(date_field)]).to eq form_response.form_field_values.find_by(form_field: date_field).formatted_localize
        expect(fields[form_tag(date_field)]).to include('2024')
      end

      it 'adds repository row answers with the row code' do
        expect(fields[form_tag(rows_field)]).to eq "Row X (#{RepositoryRow::ID_PREFIX}#{repository_row.id})"
      end

      it 'adds other answers using their formatted value' do
        expect(fields[form_tag(number_field)]).to eq form_response.form_field_values.find_by(form_field: number_field).formatted
        expect(fields[form_tag(number_field)]).to include('12')
      end

      it 'adds not applicable answers as a label' do
        expect(fields[form_tag(na_field)]).to eq I18n.t('forms.export.values.not_applicable')
        expect(fields[form_tag(na_choice_field)]).to eq I18n.t('forms.export.values.not_applicable')
      end

      it 'adds multiple and single choice answers as checklists with the chosen options checked' do
        checklists = calls[:add_checklist].to_h { |name, items, _opts| [name.to_s, items.map { |text, checked| [text, !!checked] }] }
        expect(checklists[form_tag(multi_field)]).to eq [['red', true], ['green', false], ['blue', true]]
        expect(checklists[form_tag(single_field)]).to eq [['yes', false], ['no', true]]
        expect(calls[:add_field].map { |args| args.first.to_s }).not_to include(form_tag(multi_field), form_tag(single_field))
      end

      it 'adds an unanswered multiple choice as an unchecked checklist' do
        checklists = calls[:add_checklist].to_h { |name, items, _opts| [name.to_s, items.map { |text, checked| [text, !!checked] }] }
        expect(checklists[form_tag(unanswered_multi)]).to eq [['x', false], ['y', false]]
      end
    end
  end

  describe 'results' do
    let!(:old_result) { create :result, my_module: my_module, user: user, name: 'Old result', created_at: 2.days.ago }
    let!(:new_result) { create :result, my_module: my_module, user: user, name: 'New result', created_at: 1.day.ago }

    it 'adds a field per active result ordered by creation time' do
      create(:result, my_module: my_module, user: user, name: 'Gone', archived: true, archived_on: Time.current)
      generate

      names = calls[:add_field].map(&:last)
      expect(names.index('Old result')).to be < names.index('New result')
      expect(names).not_to include('Gone')
      expect(fields[tag('result', old_result.id)]).to eq 'Old result'
    end

    it 'adds result text and tables without the protocol tags' do
      result_text = create :result_text, result: new_result, name: 'Obs', text: '<p>Cells</p>'
      table = create :table, name: 'Res grid', contents: { data: [%w(1 2)] }.to_json
      add_result_element(new_result, result_text, 0)
      add_result_element(new_result, create(:result_table, result: new_result, table: table), 1)

      generate

      text_tag = tag('result_text', result_text.id)
      table_tag = tag('result_table', table.id)
      expect(texts_for(text_tag)).to eq ["<div>Obs</div><div>{{#{text_tag}}}</div>", '<p>Cells</p>']
      expect(texts_for(table_tag)).to eq ["<div>Res grid</div><div>{{#{table_tag}}}</div>"]
      expect(calls[:add_table_from_data].map { |name, data| [name.to_s, data[:table_name]] }).to eq [[table_tag, 'Res grid']]
      expect(texts_for(:PROTOCOL)).not_to include("<div>Obs</div><div>{{PROTOCOL}}</div>")
    end

    it 'skips archived result elements' do
      result_text = create :result_text, result: new_result, name: 'Archived obs', text: '<p>x</p>'
      add_result_element(new_result, result_text, 0)
      result_text.update_columns(archived: true)

      generate

      expect(texts_for(tag('result_text', result_text.id))).to be_empty
    end
  end

  describe 'TinyMCE images' do
    let(:step) { add_step(name: 'With image', position: 0) }
    let(:step_text) { create :step_text, step: step, name: 'Pic', text: '' }
    let(:asset) { create :tiny_mce_asset, team: team, object: step_text }
    let(:token) { Base62.encode(asset.id) }
    let(:html) { "<p>before</p><img data-mce-token=\"#{token}\" width=\"#{width}\" height=\"#{height}\"><p>after</p>" }
    let(:width) { 120 }
    let(:height) { 60 }

    before do
      step_text.update!(text: html)
      add_step_element(step, step_text, 0)
    end

    it 'replaces the image with a placeholder and inserts the image file with its size' do
      generate

      placeholder = "TINY_MCE_ASSET_#{asset.id}"
      text_tag = tag('step_text', step_text.id)
      expect(texts_for(text_tag).last.delete("\n")).to eq "<p>before</p>{{#{placeholder}}}<p>after</p>"
      name, path, options = calls[:add_inline_image].first
      expect(name).to eq placeholder.to_sym
      expect(path).to end_with('.jpg')
      expect(options).to eq(width: 120, height: 60)
    end

    context 'without width and height attributes' do
      let(:html) { "<img data-mce-token=\"#{token}\">" }

      it 'uses the analysed size of the variant' do
        generate
        _name, _path, options = calls[:add_inline_image].first
        expect(options[:width]).to be_a(Integer).and be > 0
        expect(options[:height]).to be_a(Integer).and be > 0
      end
    end

    it 'removes the downloaded image files afterwards' do
      generate
      files = service.instance_variable_get(:@tiny_mce_assets).map { |a| a[:file] }
      expect(files).not_to be_empty
      expect(files.map(&:path)).to all(be_nil)
    end

    it 'keeps the original image markup and logs when the image cannot be processed' do
      allow_any_instance_of(ActiveStorage::Blob).to receive(:variant).and_raise(StandardError, 'no vips')
      allow(Rails.logger).to receive(:error)

      generate

      expect(calls[:add_inline_image]).to be_empty
      expect(texts_for(tag('step_text', step_text.id)).last).to include("data-mce-token=\"#{token}\"")
      expect(Rails.logger).to have_received(:error).with('no vips').at_least(:once)
    end

    it 'ignores attached images that are not referenced in the text' do
      step_text.update!(text: '<p>plain</p>')
      generate
      expect(calls[:add_inline_image]).to be_empty
      expect(texts_for(tag('step_text', step_text.id)).last.strip).to eq '<p>plain</p>'
    end

    it 'skips assets without an attached image' do
      asset.image.purge
      generate
      expect(calls[:add_inline_image]).to be_empty
    end
  end
end
