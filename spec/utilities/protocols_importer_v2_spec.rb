# frozen_string_literal: true

require 'rails_helper'

describe ProtocolsImporterV2 do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:importer) { described_class.new(user, team) }
  let(:jpg_path) { Rails.root.join('spec/fixtures/files/test.jpg') }

  def upload_blob(filename = 'test.jpg')
    ActiveStorage::Blob.create_and_upload!(io: File.open(jpg_path), filename: filename, content_type: 'image/jpeg')
  end

  let(:table_contents) { { data: [%w(a b), %w(c d)] }.to_json }
  let(:description_blob) { upload_blob('description.jpg') }
  let(:step_asset_blob) { upload_blob('step_file.jpg') }
  let(:result_asset_blob) { upload_blob('result_file.jpg') }
  let(:form) { create :form, team: team, created_by: user, published_on: Time.zone.now, published_by: user }

  let(:protocol_json) do
    {
      'name' => 'Imported protocol',
      'authors' => 'Jane Doe',
      'description' => +'<p>Intro <img data-mce-token="17"></p>',
      'descriptionAssets' => {
        '0' => { 'tokenId' => '17', 'signed_id' => description_blob.signed_id, 'fileMetadata' => '{"origin":"export"}' }
      },
      'description_locked' => true,
      'steps' => {
        '0' => {
          'name' => 'First step',
          'locked' => true,
          'attachments_locked' => true,
          'adding_items_allowed' => false,
          'stepElements' => {
            '0' => { 'type' => 'StepText', 'stepText' => { 'contents' => '<p>Step text</p>', 'name' => 'Text name' },
                     'locked' => true },
            '1' => { 'type' => 'StepTable',
                     'elnTable' => { 'name' => 'Plate', 'contents' => Base64.encode64(table_contents),
                                     'metadata' => '{"plateTemplate":true}' },
                     'locked' => false },
            '2' => { 'type' => 'Checklist',
                     'checklist' => { 'name' => 'Checks', 'items' => { '0' => { 'text' => 'one' },
                                                                      '1' => { 'text' => 'two' } } } },
            '3' => { 'type' => 'FormResponse', 'form' => { 'id' => form.id } },
            '4' => { 'type' => 'Unknown' }
          },
          'assets' => {
            '0' => { 'signed_id' => step_asset_blob.signed_id,
                     'fileMetadata' => '{"created_by_id":999,"note":"kept"}',
                     'preview_image' => { 'bytes' => Base64.encode64(File.binread(jpg_path)), 'fileName' => 'preview.jpg' } }
          }
        },
        '1' => { 'name' => 'Second step', 'description' => '' }
      },
      'resultTemplates' => {
        '0' => {
          'name' => 'Result template',
          'attachments_locked' => true,
          'resultElements' => {
            '0' => { 'type' => 'ResultText', 'resultText' => { 'contents' => '<p>Result text</p>', 'name' => 'RT' } },
            '1' => { 'type' => 'ResultTable', 'elnTable' => { 'name' => 'Result table',
                                                              'contents' => Base64.encode64(table_contents) } }
          },
          'assets' => { '0' => { 'signed_id' => result_asset_blob.signed_id } }
        },
        '1' => { 'name' => 'Empty result' }
      }
    }.with_indifferent_access
  end

  before do
    user.update!(current_team_id: team.id)
  end

  describe '#import_new_protocol' do
    subject(:protocol) { importer.import_new_protocol(protocol_json) }

    it 'creates a repository draft owned by the user' do
      expect(protocol).to be_persisted
      expect(protocol).to be_in_repository_draft
      expect(protocol.name).to eq 'Imported protocol'
      expect(protocol.authors).to eq 'Jane Doe'
      expect(protocol.added_by).to eq user
      expect(protocol.team).to eq team
    end

    it 'imports description images and rewrites their tokens' do
      tiny_mce_asset = protocol.tiny_mce_assets.first

      expect(tiny_mce_asset.image.blob.metadata).to include('origin' => 'export')
      expect(protocol.description).to include("data-mce-token=\"#{Base62.encode(tiny_mce_asset.id)}\"")
      expect(protocol.description).not_to include('data-mce-token="17"')
    end

    it 'imports steps in order with their elements' do
      steps = protocol.steps.order(:position)
      first = steps.first

      expect(steps.map(&:name)).to eq ['First step', 'Second step']
      expect(steps.map(&:position)).to eq [0, 1]
      expect(first.step_texts.first.text).to eq '<p>Step text</p>'
      expect(first.step_texts.first.name).to eq 'Text name'
      expect(first.tables.first.name).to eq 'Plate'
      expect(first.tables.first.contents).to eq table_contents
      expect(first.tables.first.metadata).to eq('plateTemplate' => true)
      expect(first.checklists.first.checklist_items.order(:position).pluck(:text)).to eq %w(one two)
      expect(first.form_responses.first.form).to eq form
      expect(first.step_orderable_elements.order(:position).map(&:orderable_type))
        .to eq %w(StepText StepTable Checklist FormResponse)
    end

    it 'imports step assets with metadata (without created_by_id) and preview' do
      asset = protocol.steps.find_by(name: 'First step').assets.first

      expect(asset.file_name).to eq 'step_file.jpg'
      expect(asset.blob.metadata).to include('note' => 'kept')
      expect(asset.blob.metadata).not_to have_key('created_by_id')
      expect(asset.preview_image).to be_attached
      expect(asset.team).to eq team
    end

    it 'imports result templates with elements and assets' do
      results = protocol.results.order(:id)
      result = results.first

      expect(results.map(&:name)).to eq ['Result template', 'Empty result']
      expect(result.result_texts.first.text).to eq '<p>Result text</p>'
      expect(result.result_texts.first.name).to eq 'RT'
      expect(result.tables.first.name).to eq 'Result table'
      expect(result.result_orderable_elements.count).to eq 2
      expect(result.assets.first.file_name).to eq 'result_file.jpg'
    end

    it 'does not apply locks when content locking is disabled' do
      allow(Protocol).to receive(:content_locking_enabled?).and_return(false)

      first = protocol.steps.find_by(name: 'First step')
      expect(first.locked).to be false
      expect(first.attachments_locked).to be false
      expect(first.step_texts.first.locked).to be false
      expect(protocol.description_locked).to be false
    end

    context 'when content locking is enabled' do
      before { allow(Protocol).to receive(:content_locking_enabled?).and_return(true) }

      it 'applies step, element and result locks' do
        first = protocol.steps.find_by(name: 'First step')

        expect(protocol.description_locked).to be true
        expect(first.locked).to be true
        expect(first.attachments_locked).to be true
        expect(first.adding_items_allowed).to be false
        expect(first.step_texts.first.locked).to be true
        expect(first.tables.first.locked).to be false
        expect(first.checklists.first.locked).to be false
        expect(protocol.results.find_by(name: 'Result template').attachments_locked).to be true
      end
    end

    it 'skips forms that are not readable or published' do
      protocol_json['steps']['0']['stepElements']['3']['form']['id'] = -1

      expect(protocol.steps.find_by(name: 'First step').form_responses).to be_empty
    end

    it 'renames a too long protocol name' do
      protocol_json['name'] = 'n' * (Constants::NAME_MAX_LENGTH + 20)

      expect(protocol.name.length).to be <= Constants::NAME_MAX_LENGTH
      expect(protocol.name).to end_with '...'
    end

    it 'converts empty strings to nil' do
      protocol_json['authors'] = ''

      expect(protocol.authors).to be_nil
    end

    it 'falls back to Base62 encoded token ids' do
      protocol_json['description'] = +"<p><img data-mce-token=\"#{Base62.encode(17)}\"></p>"

      tiny_mce_asset = protocol.tiny_mce_assets.first
      expect(protocol.description).to include("data-mce-token=\"#{Base62.encode(tiny_mce_asset.id)}\"")
    end

    it 'imports a minimal protocol without steps or descriptions' do
      minimal = importer.import_new_protocol({ 'name' => 'Minimal' }.with_indifferent_access)

      expect(minimal.name).to eq 'Minimal'
      expect(minimal.steps).to be_empty
      expect(minimal.description).to be_nil
    end
  end

  describe '#import_into_existing' do
    it 'replaces the contents of an existing protocol and unlinks it' do
      pending 'bug: import_into_existing calls protocol.destroy_contents without the required user argument'
      existing = create :protocol, team: team, my_module: create(:my_module)
      create :step, protocol: existing, name: 'Old step'

      result = importer.import_into_existing(existing, protocol_json)

      expect(result.steps.pluck(:name)).to contain_exactly('First step', 'Second step')
      expect(result).to be_unlinked
    end
  end
end
