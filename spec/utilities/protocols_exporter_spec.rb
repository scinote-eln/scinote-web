# frozen_string_literal: true

require 'rails_helper'

describe ProtocolsExporter do
  let(:exporter) { Class.new { include ProtocolsExporter }.new }
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:protocol) do
    create :protocol, :in_repository_draft, team: team, added_by: user, name: 'Exported', authors: 'Author'
  end

  def call(method, *args)
    exporter.send(method, *args)
  end

  def parse(xml)
    Nokogiri::XML(xml).tap(&:remove_namespaces!)
  end

  describe '#get_guid' do
    it 'builds a zero padded guid from the id' do
      expect(call(:get_guid, 42)).to eq '00000000-0000-4000-0000-000000000042'
    end
  end

  describe '#get_protocol_name' do
    it 'returns the protocol name' do
      expect(call(:get_protocol_name, protocol)).to eq 'Exported'
    end

    it 'falls back to the task name for unnamed task protocols' do
      my_module = create :my_module, name: 'Task name'
      task_protocol = my_module.protocol
      task_protocol.update_column(:name, nil)

      expect(call(:get_protocol_name, task_protocol)).to eq 'Task name'
    end
  end

  describe '#generate_envelope_xml' do
    it 'lists the latest published version of every protocol' do
      published = create :protocol, :in_repository_published_original, team: team, added_by: user, name: 'Published'

      doc = parse(call(:generate_envelope_xml, [protocol, published]))

      expect(doc.root['version']).to eq '1.0'
      expect(doc.xpath('//protocol').map(&:text)).to eq %w(Exported Published)
      expect(doc.xpath('//protocol').map { |p| p['guid'] }).to eq [call(:get_guid, protocol.id), call(:get_guid, published.id)]
    end
  end

  describe '#get_tiny_mce_assets' do
    it 'returns nil for nil text' do
      expect(call(:get_tiny_mce_assets, nil)).to be_nil
    end

    it 'describes referenced images and skips unknown tokens' do
      image = create :tiny_mce_asset, team: team
      text = "<img data-mce-token=\"#{Base62.encode(image.id)}\"><img data-mce-token=\"#{Base62.encode(0)}\">"

      doc = parse(call(:get_tiny_mce_assets, text))
      assets = doc.xpath('//tinyMceAsset')

      expect(assets.size).to eq 1
      expect(assets.first['id']).to eq image.id.to_s
      expect(assets.first['fileRef']).to eq "rte-#{call(:get_guid, image.id)}.jpg"
      expect(assets.first.at_xpath('fileName').text).to eq 'test.jpg'
      expect(assets.first.at_xpath('fileType').text).to eq 'image/jpeg'
    end
  end

  describe '#generate_protocol_xml' do
    let!(:image) { create :tiny_mce_asset, team: team, object: protocol }
    let!(:step) do
      create :step, protocol: protocol, name: 'Step A', position: 0, description: '<p>Step description</p>'
    end
    let!(:archived_step) { create :step, protocol: protocol, name: 'Archived', position: nil, archived: true }
    let!(:step_asset) { create :step_asset, step: step }
    let!(:table) { create(:step_table, step: step, table: create(:table, name: 'T1', team: team)).table }
    let!(:checklist) { create :checklist, step: step, name: 'C1' }
    let!(:item) { create :checklist_item, checklist: checklist, text: 'do it', position: 0 }

    before do
      protocol.update_column(:description, "<p>Hello <img data-mce-token=\"#{Base62.encode(image.id)}\"></p>")
    end

    it 'exports protocol, active steps and their content' do
      doc = parse(call(:generate_protocol_xml, protocol))
      xml_protocol = doc.at_xpath('//eln/protocol')
      xml_step = xml_protocol.at_xpath('steps/step')

      expect(doc.root['version']).to eq '1.0'
      expect(xml_protocol.at_xpath('name').text).to eq 'Exported'
      expect(xml_protocol.at_xpath('authors').text).to eq 'Author'
      expect(xml_protocol.at_xpath('description').inner_html).to include('Hello')
      expect(xml_protocol.xpath('descriptionAssets/tinyMceAsset').first['id']).to eq image.id.to_s
      expect(xml_protocol.xpath('steps/step').size).to eq 1
      expect(xml_step['position']).to eq '0'
      expect(xml_step.at_xpath('name').text).to eq 'Step A'
      expect(xml_step.at_xpath('description').inner_html).to include('Step description')
      expect(xml_step.at_xpath('assets/asset/fileName').text).to eq 'test.jpg'
      expect(xml_step.at_xpath('elnTables/elnTable/name').text).to eq 'T1'
      expect([xml_step.at_xpath('elnTables/elnTable/contents').text].pack('H*')).to eq table.contents
      expect(xml_step.at_xpath('checklists/checklist/name').text).to eq 'C1'
      expect(xml_step.at_xpath('checklists/checklist/items/item/text').text).to eq 'do it'
    end

    it 'exports a protocol without steps' do
      empty = create :protocol, :in_repository_draft, team: team, added_by: user, name: 'Empty'

      doc = parse(call(:generate_protocol_xml, empty))

      expect(doc.xpath('//steps')).to be_empty
      expect(doc.xpath('//descriptionAssets')).to be_empty
    end
  end

  describe 'xsd generators' do
    it 'generates a parseable envelope schema' do
      pending 'bug: generated XSD declares an attribute named "xmlns", which Nokogiri/libxml2 rejects as an invalid schema'
      schema = Nokogiri::XML::Schema(call(:generate_envelope_xsd))

      expect(schema).to be_a Nokogiri::XML::Schema
      envelope = call(:generate_envelope_xml, [protocol])
      expect(schema.validate(Nokogiri::XML(envelope)).map(&:message).join).not_to include('envelope')
    end

    it 'generates an eln schema with the expected elements' do
      xsd = call(:generate_eln_xsd)

      expect(xsd).to include('<xs:element name="eln">', '<xs:element name="tinyMceAsset" maxOccurs="unbounded">')
    end

    it 'generates a parseable eln schema' do
      pending 'bug: generated XSD declares an attribute named "xmlns", which Nokogiri/libxml2 rejects as an invalid schema'
      expect(Nokogiri::XML::Schema(call(:generate_eln_xsd))).to be_a Nokogiri::XML::Schema
    end
  end
end
