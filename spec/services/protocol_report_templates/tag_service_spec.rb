# frozen_string_literal: true

require 'rails_helper'

describe ProtocolReportTemplates::TagService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:protocol) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:service) { described_class.new(protocol) }

  def tag_for(type, id)
    "{{#{I18n.t("protocols.report_template.data_inputs.codes.type.#{type}")}_#{id}}}"
  end

  # Builds a protocol with one step holding a text, table, checklist and form response, plus one result template
  def build_content(target, suffix)
    step = create :step, protocol: target, name: "Step #{suffix}", position: 0
    text = create :step_text, step: step, name: "Text #{suffix}"
    table = create :step_table, step: step, table: create(:table, name: "Table #{suffix}", team: team)
    checklist = create :checklist, step: step, name: "Checklist #{suffix}"
    form = create :form, team: team, created_by: user
    fields = Array.new(2) { |i| create :form_field, form: form, position: i, name: "Field #{suffix}#{i}" }
    response = create :form_response, form: form, created_by: user, parent: step

    [text, table, checklist, response].each_with_index do |orderable, position|
      step.step_orderable_elements.create!(position: position, orderable: orderable)
    end

    result = create :result_template, protocol: target, user: user, name: "Result #{suffix}"
    result_text = create :result_text, result: result, name: "Result text #{suffix}"
    result_table = create :result_table, result: result, table: create(:table, name: "Result table #{suffix}", team: team)
    [result_text, result_table].each_with_index do |orderable, position|
      result.result_orderable_elements.create!(position: position, orderable: orderable)
    end

    { step: step, text: text, table: table.table, checklist: checklist, form: response, fields: fields,
      result: result, result_text: result_text, result_table: result_table.table }
  end

  describe '#tags' do
    let!(:content) { build_content(protocol, 'A') }
    let(:tags) { service.tags }
    let(:step_group) { tags.find { |t| t[:tag] == tag_for('step', content[:step].id) } }
    let(:result_group) { tags.find { |t| t[:tag] == tag_for('result', content[:result].id) } }

    it 'starts with the default task placeholders' do
      group = tags.first

      expect(group[:label]).to eq 'General task data'
      expect(group[:inputs]).to eq(
        %w(task_name task_due_date task_tags task_protocol).map do |input|
          {
            label: I18n.t("protocols.report_template.data_inputs.codes.#{input}"),
            tag: I18n.t("protocols.report_template.data_inputs.codes.#{input}_code")
          }
        end
      )
    end

    it 'adds one group per step followed by one per result' do
      expect(tags.size).to eq 3
      expect(step_group[:label]).to eq 'Step A'
      expect(result_group[:label]).to eq 'Result A'
      expect(tags.last).to eq result_group
    end

    it 'lists step elements with labels, tags and icons' do
      inputs = step_group[:inputs]

      expect(inputs.first(3)).to eq [
        { label: 'Text A', tag: tag_for('step_text', content[:text].id), icon: 'sn-icon-result-text' },
        { label: 'Table A', tag: tag_for('step_table', content[:table].id), icon: 'sn-icon-tables' },
        { label: 'Checklist A', tag: tag_for('checklist', content[:checklist].id), icon: 'sn-icon-checkllist' }
      ]
    end

    it 'expands form responses into the form and each of its fields' do
      inputs = step_group[:inputs].drop(3)
      form_id = content[:form].id

      expect(inputs.first).to eq(label: content[:form].form.name, tag: tag_for('form_response', form_id),
                                 icon: 'sn-icon-forms')
      expect(inputs.drop(1)).to eq(
        content[:fields].map do |field|
          { label: field.name, tag: "{{FORM_#{form_id}_FIELD_#{field.id}}}" }
        end
      )
    end

    it 'lists result elements' do
      expect(result_group[:inputs]).to eq [
        { label: 'Result text A', tag: tag_for('result_text', content[:result_text].id), icon: 'sn-icon-result-text' },
        { label: 'Result table A', tag: tag_for('result_table', content[:result_table].id), icon: 'sn-icon-tables' }
      ]
    end

    it 'only returns defaults for an empty protocol' do
      expect(described_class.new(create(:protocol, :in_repository_draft, team: team, added_by: user)).tags.size).to eq 1
    end
  end

  describe 'template rewriting' do
    let(:src_protocol) { create :protocol, :in_repository_draft, team: team, added_by: user }
    let!(:src) { build_content(src_protocol, 'src') }
    let!(:dest) { build_content(protocol, 'dest') }
    let(:src_template) { create :report_template_stub, protocol: src_protocol }

    def odt_with(content_text)
      buffer = Zip::OutputStream.write_buffer do |zip|
        zip.put_next_entry('mimetype')
        zip.write 'application/vnd.oasis.opendocument.text'
        zip.put_next_entry('META-INF/manifest.xml')
        zip.write '<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0"/>'
        zip.put_next_entry('content.xml')
        zip.write '<?xml version="1.0" encoding="UTF-8"?>' \
                  '<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" ' \
                  'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"><office:body><office:text>' \
                  "<text:p>#{content_text}</text:p></office:text></office:body></office:document-content>"
        zip.put_next_entry('styles.xml')
        zip.write '<?xml version="1.0" encoding="UTF-8"?><office:document-styles ' \
                  'xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"/>'
      end
      buffer.string
    end

    def build_template(subject, content_text)
      template = ReportTemplate.create!(name: 'Template', subject: subject)
      template.odt_template_file.attach(io: StringIO.new(odt_with(content_text)), filename: 'tpl.odt',
                                        content_type: 'application/vnd.oasis.opendocument.text')
      template
    end

    def content_xml(template)
      Zip::InputStream.open(StringIO.new(template.odt_template_file.download)) do |io|
        while (entry = io.get_next_entry)
          return io.read if entry.name == 'content.xml'
        end
      end
    end

    describe '#replace_tags' do
      let(:src_text) do
        "{{STEP_#{src[:step].id}}} {{STEP_TEXT_#{src[:text].id}}} {{STEP_TABLE_#{src[:table].id}}} " \
          "{{CHECKLIST_#{src[:checklist].id}}} {{FORM_#{src[:form].id}}} " \
          "{{FORM_#{src[:form].id}_FIELD_#{src[:fields].first.id}}} " \
          "{{RESULT_#{src[:result].id}}} {{RESULT_TEXT_#{src[:result_text].id}}} " \
          "{{RESULT_TABLE_#{src[:result_table].id}}}"
      end
      let(:source_template) { build_template(src_protocol, src_text) }
      let(:dest_template) { ReportTemplate.create!(name: 'Dest', subject: protocol) }

      it 'maps every source tag to the matching tag of the destination protocol' do
        service.replace_tags(source_template, dest_template, src_protocol)
        xml = content_xml(dest_template)

        expect(xml).to include(tag_for('step', dest[:step].id), tag_for('step_text', dest[:text].id),
                               tag_for('step_table', dest[:table].id), tag_for('checklist', dest[:checklist].id),
                               tag_for('form_response', dest[:form].id),
                               "{{FORM_#{dest[:form].id}_FIELD_#{dest[:fields].first.id}}}",
                               tag_for('result', dest[:result].id), tag_for('result_text', dest[:result_text].id),
                               tag_for('result_table', dest[:result_table].id))
        expect(xml).not_to include("{{STEP_#{src[:step].id}}}", "{{CHECKLIST_#{src[:checklist].id}}}")
        expect(dest_template.odt_template_file.filename.to_s).to eq 'tpl.odt'
      end

      it 'keeps result tags untouched when results are excluded' do
        service.replace_tags(source_template, dest_template, src_protocol, include_results: false)
        xml = content_xml(dest_template)

        expect(xml).to include(tag_for('step', dest[:step].id))
        expect(xml).to include("{{RESULT_#{src[:result].id}}}")
        expect(xml).not_to include(tag_for('result', dest[:result].id))
      end
    end

    describe '#replace_form_response_tags' do
      it 'rewrites only the form response and its field tags' do
        template = build_template(
          protocol,
          "{{FORM_#{src[:form].id}}} {{FORM_#{src[:form].id}_FIELD_#{src[:fields].last.id}}} {{STEP_#{src[:step].id}}}"
        )

        service.replace_form_response_tags(template, src[:form], dest[:form])
        xml = content_xml(template)

        expect(xml).to include(tag_for('form_response', dest[:form].id),
                               "{{FORM_#{dest[:form].id}_FIELD_#{dest[:fields].last.id}}}")
        expect(xml).to include("{{STEP_#{src[:step].id}}}")
      end
    end
  end
end
