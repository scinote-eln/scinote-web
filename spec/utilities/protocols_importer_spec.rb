# frozen_string_literal: true

require 'rails_helper'

describe ProtocolsImporter do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:importer) { described_class.new(user, team) }
  let(:jpg_path) { Rails.root.join('spec/fixtures/files/test.jpg') }
  let(:table_contents) { { data: [%w(a b)] }.to_json }

  def upload_blob(filename)
    ActiveStorage::Blob.create_and_upload!(io: File.open(jpg_path), filename: filename, content_type: 'image/jpeg')
  end

  let(:description_blob) { upload_blob('description.jpg') }
  let(:step_image_blob) { upload_blob('step_image.jpg') }
  let(:step_asset_blob) { upload_blob('step_file.jpg') }

  let(:protocol_json) do
    {
      'name' => 'Legacy protocol',
      'authors' => '',
      'description' => +'<p>Intro [~tiny_mce_id:42]</p>',
      'descriptionAssets' => {
        '0' => { 'tokenId' => '42', 'signed_id' => description_blob.signed_id, 'fileMetadata' => '{"src":"v1"}' }
      },
      'steps' => {
        '0' => {
          'name' => 'Step one',
          'description' => +'<p>Step <img data-mce-token="7"></p>',
          'descriptionAssets' => { '0' => { 'tokenId' => '7', 'signed_id' => step_image_blob.signed_id } },
          'checklists' => {
            '0' => { 'name' => 'Checks', 'items' => { '0' => { 'text' => 'a' }, '1' => { 'text' => 'b' } } },
            '1' => { 'name' => 'Empty checklist' }
          },
          'tables' => { '0' => { 'name' => 'Table', 'contents' => Base64.encode64(table_contents) } },
          'assets' => {
            '0' => { 'signed_id' => step_asset_blob.signed_id, 'fileMetadata' => '{"created_by_id":5,"k":"v"}' }
          }
        },
        '1' => {
          'name' => 'Step two',
          'description' => '<p>Legacy <img data-mce-token="99"> text  ]]--&gt;</p>'
        }
      }
    }.with_indifferent_access
  end

  describe '#import_new_protocol' do
    subject(:protocol) { importer.import_new_protocol(protocol_json) }

    it 'creates a repository draft' do
      expect(protocol).to be_persisted
      expect(protocol).to be_in_repository_draft
      expect(protocol.name).to eq 'Legacy protocol'
      expect(protocol.authors).to be_nil
      expect(protocol.added_by).to eq user
    end

    it 'converts old tiny mce tags and links imported images' do
      tiny_mce_asset = protocol.tiny_mce_assets.first

      expect(tiny_mce_asset.image.blob.metadata).to include('src' => 'v1')
      expect(protocol.description).to include("data-mce-token=\"#{Base62.encode(tiny_mce_asset.id)}\"")
      expect(protocol.description).not_to include('[~tiny_mce_id:42]')
    end

    it 'imports steps with description texts, checklists, tables and assets' do
      first, second = protocol.steps.order(:position).to_a
      step_text = first.step_texts.first

      expect([first.name, second.name]).to eq ['Step one', 'Step two']
      expect(step_text.text).to include("data-mce-token=\"#{Base62.encode(step_text.tiny_mce_assets.first.id)}\"")
      expect(first.checklists.order(:id).map(&:name)).to eq ['Checks', 'Empty checklist']
      expect(first.checklists.find_by(name: 'Checks').checklist_items.order(:position).pluck(:text)).to eq %w(a b)
      expect(first.tables.first.contents).to eq table_contents
      expect(first.step_orderable_elements.order(:position).map(&:orderable_type))
        .to eq %w(StepText Checklist Checklist StepTable)

      asset = first.assets.first
      expect(asset.file_name).to eq 'step_file.jpg'
      expect(asset.blob.metadata).to include('k' => 'v')
      expect(asset.blob.metadata).not_to have_key('created_by_id')
    end

    it 'strips tiny mce tokens from legacy descriptions without assets' do
      second = protocol.steps.find_by(name: 'Step two')

      expect(second.step_texts.first.text).to eq '<p>Legacy <img > text</p>'
    end

    it 'imports a protocol without description or steps' do
      minimal = importer.import_new_protocol({ 'name' => 'Minimal' }.with_indifferent_access)

      expect(minimal.description).to be_nil
      expect(minimal.steps).to be_empty
    end

    it 'keeps a renamed name for too long names' do
      protocol_json['name'] = 'n' * (Constants::NAME_MAX_LENGTH + 5)

      expect(protocol.reload.name.length).to eq Constants::NAME_MAX_LENGTH
      expect(protocol.name).to end_with '...'
    end
  end

  describe '#import_into_existing' do
    it 'replaces contents of an existing protocol' do
      pending 'bug: import_into_existing calls protocol.destroy_contents without the required user argument'
      existing = create :protocol, team: team, my_module: create(:my_module)

      expect(importer.import_into_existing(existing, protocol_json).steps.count).to eq 2
    end
  end
end
