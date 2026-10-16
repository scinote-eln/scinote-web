# frozen_string_literal: true

require 'rails_helper'

describe ProtocolsExporterV2 do
  let(:exporter) { Class.new { include ProtocolsExporterV2 }.new }
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:protocol) do
    create :protocol, :in_repository_draft, team: team, added_by: user, name: 'Exported', authors: 'Author',
                                            description: '<p>Protocol description</p>'
  end

  def call(method, *args)
    exporter.send(method, *args)
  end

  def parse(xml)
    Nokogiri::XML(xml).tap(&:remove_namespaces!)
  end

  describe '#generate_envelope_xml' do
    it 'lists the latest published version of every protocol with version 1.2' do
      published = create :protocol, :in_repository_published_original, team: team, added_by: user, name: 'Published'

      doc = parse(call(:generate_envelope_xml, [protocol, published]))

      expect(doc.root['version']).to eq '1.2'
      expect(doc.xpath('//protocol').map(&:text)).to eq %w(Exported Published)
      expect(doc.xpath('//protocol').map { |p| p['guid'] })
        .to eq [call(:get_guid, protocol.id), call(:get_guid, published.id)]
    end
  end

  describe '#generate_protocol_xml' do
    let!(:step) { create :step, protocol: protocol, name: 'Step A', position: 0 }
    let!(:archived_step) { create :step, protocol: protocol, name: 'Archived', position: nil, archived: true }
    let!(:step_asset) { create :step_asset, step: step }
    let!(:step_text) { create :step_text, step: step, name: 'Text 1', text: '<p>Step text body</p>' }
    let!(:step_table) { create :step_table, step: step, table: create(:table, name: 'T1', team: team) }
    let!(:checklist) { create :checklist, step: step, name: 'C1' }
    let!(:item) { create :checklist_item, checklist: checklist, text: 'do it', position: 0 }
    let!(:form) { create :form, team: team, created_by: user }
    let!(:form_response) { create :form_response, form: form, created_by: user, parent: step }

    before do
      step_table.table.update!(locked: true)
      [step_text, step_table, checklist].each_with_index do |orderable, i|
        step.step_orderable_elements.create!(position: i, orderable: orderable)
      end
      form_response.step_orderable_element&.update!(step: step, position: 3)
    end

    def element(doc, type)
      doc.at_xpath("//stepElement[@type='#{type}']")
    end

    it 'exports protocol attributes and only active steps' do
      doc = parse(call(:generate_protocol_xml, protocol))
      xml_protocol = doc.at_xpath('//eln/protocol')

      expect(doc.root['version']).to eq '1.2'
      expect(xml_protocol['guid']).to eq call(:get_guid, protocol.id)
      expect(xml_protocol['description_locked']).to eq protocol.description_locked.to_s
      expect(xml_protocol.at_xpath('name').text).to eq 'Exported'
      expect(xml_protocol.at_xpath('authors').text).to eq 'Author'
      expect(xml_protocol.at_xpath('description').inner_html).to include('Protocol description')
      expect(xml_protocol.xpath('steps/step').size).to eq 1
      expect(xml_protocol.at_xpath('steps/step/name').text).to eq 'Step A'
    end

    it 'exports step flags, assets and every element type' do
      xml_step = parse(call(:generate_protocol_xml, protocol)).at_xpath('//steps/step')

      expect(xml_step['position']).to eq '0'
      expect(xml_step['locked']).to eq step.locked.to_s
      expect(xml_step.at_xpath('assets/asset/fileName').text).to eq 'test.jpg'
      expect(xml_step.xpath('stepElements/stepElement').map { |e| e['type'] })
        .to match_array %w(StepText StepTable Checklist FormResponse)
    end

    it 'exports text, table, checklist and form elements' do
      doc = parse(call(:generate_protocol_xml, protocol))

      expect(element(doc, 'StepText').at_xpath('stepText/name').text).to eq 'Text 1'
      expect(element(doc, 'StepText').at_xpath('stepText/contents').inner_html).to include('Step text body')
      table_el = element(doc, 'StepTable')
      expect(table_el['locked']).to eq 'true'
      expect(table_el.at_xpath('elnTable/name').text).to eq 'T1'
      expect([table_el.at_xpath('elnTable/contents').text].pack('H*')).to eq step_table.table.contents
      checklist_el = element(doc, 'Checklist')
      expect(checklist_el.at_xpath('checklist/name').text).to eq 'C1'
      expect(checklist_el.at_xpath('checklist/items/item/text').text).to eq 'do it'
      form_el = element(doc, 'FormResponse')
      expect(form_el.at_xpath('form')['guid']).to eq call(:get_guid, form.id)
    end

    it 'exports a checklist without items and text without body' do
      checklist.checklist_items.destroy_all
      step_text.update_column(:text, nil)

      doc = parse(call(:generate_protocol_xml, protocol))

      expect(doc.at_xpath('//checklist/items')).to be_nil
      expect(doc.at_xpath('//stepText/tinyMceAsset')).to be_nil
    end

    it 'embeds description tinymce assets' do
      image = create :tiny_mce_asset, team: team, object: protocol
      protocol.update_column(:description, "<p><img data-mce-token=\"#{Base62.encode(image.id)}\"></p>")

      doc = parse(call(:generate_protocol_xml, protocol.reload))

      expect(doc.xpath('//eln/protocol/descriptionAssets/tinyMceAsset').first['id']).to eq image.id.to_s
    end

    it 'exports a protocol without steps' do
      empty = create :protocol, :in_repository_draft, team: team, added_by: user, name: 'Empty'

      doc = parse(call(:generate_protocol_xml, empty))

      expect(doc.xpath('//steps')).to be_empty
      expect(doc.at_xpath('//resultTemplates').children.reject(&:text?)).to be_empty
    end

    context 'with result templates' do
      let!(:result_template) do
        create :result_template, protocol: protocol, user: user, name: 'Result A', attachments_locked: true
      end
      let!(:result_asset) { create :result_asset, result: result_template }
      let!(:result_text) { create :result_text, result: result_template, name: 'RT', text: '<p>Result body</p>' }
      let!(:result_table) { create :result_table, result: result_template, table: create(:table, name: 'RTab', team: team) }

      before do
        [result_text, result_table].each_with_index do |orderable, i|
          result_template.result_orderable_elements.create!(position: i, orderable: orderable)
        end
      end

      it 'exports result templates with assets and elements' do
        doc = parse(call(:generate_protocol_xml, protocol))
        xml_result = doc.at_xpath('//resultTemplates/resultTemplate')

        expect(xml_result['attachments_locked']).to eq 'true'
        expect(xml_result.at_xpath('name').text).to eq 'Result A'
        expect(xml_result.at_xpath('assets/asset/fileName').text).to eq 'test.jpg'
        expect(xml_result.xpath('resultElements/resultElement').map { |e| e['type'] })
          .to match_array %w(ResultText ResultTable)
        expect(xml_result.at_xpath('.//resultText/name').text).to eq 'RT'
        expect(xml_result.at_xpath('.//resultText/contents').inner_html).to include('Result body')
        expect(xml_result.at_xpath('.//elnTable/name').text).to eq 'RTab'
      end

      it 'exports task results for protocols in a task' do
        my_module = create :my_module, created_by: user
        task_protocol = my_module.protocol
        create :result, my_module: my_module, user: user, name: 'Task result'
        create :result, :archived, my_module: my_module, user: user, name: 'Gone'

        names = parse(call(:generate_protocol_xml, task_protocol)).xpath('//resultTemplate/name').map(&:text)

        expect(names).to eq ['Task result']
      end
    end
  end

  describe '#prepare_asset_for_export' do
    let(:step) { create :step, protocol: protocol }

    def zip_entries
      buffer = Zip::OutputStream.write_buffer { |ostream| yield ostream }
      buffer.rewind
      entries = {}
      Zip::InputStream.open(buffer) do |io|
        while (entry = io.get_next_entry)
          entries[entry.name] = io.read
        end
      end
      entries
    end

    it 'writes the attached file under the guid based name' do
      asset = create(:step_asset, step: step).asset

      entries = zip_entries { |ostream| call(:prepare_asset_for_export, ostream, asset, 'dir') }

      expect(entries.keys).to eq ["dir/#{call(:get_guid, asset.id)}.jpg"]
      expect(entries.values.first).to eq asset.file.download
    end

    it 'skips assets without an attached file' do
      asset = create(:step_asset, step: step).asset
      asset.file.detach

      entries = zip_entries { |ostream| call(:prepare_asset_for_export, ostream, asset, 'dir') }

      expect(entries).to be_empty
    end

    it 'also writes the preview image when present' do
      asset = create(:step_asset, step: step).asset
      asset.preview_image.attach(io: StringIO.new('preview'), filename: 'prev.png', content_type: 'image/png')

      entries = zip_entries { |ostream| call(:prepare_asset_for_export, ostream, asset, 'dir') }

      expect(entries["dir/previews/#{call(:get_guid, asset.id)}.png"]).to eq 'preview'
      expect(entries.keys).to include("dir/#{call(:get_guid, asset.id)}.jpg")
    end
  end
end
