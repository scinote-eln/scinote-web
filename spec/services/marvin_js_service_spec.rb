# frozen_string_literal: true

require 'rails_helper'

describe MarvinJsService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:image_path) { Rails.root.join('spec/fixtures/files/test.jpg') }
  let(:image) { "data:image/jpeg;base64,#{Base64.strict_encode64(File.binread(image_path))}" }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:step) { create :step, protocol: my_module.protocol, user: user }
  let(:result) { create :result, my_module: my_module, user: user }

  def with_env(values)
    old = values.keys.to_h { |k| [k, ENV[k]] }
    values.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  describe '.url' do
    it 'returns the configured MARVINJS_URL' do
      with_env('MARVINJS_URL' => 'https://marvin.example.com') do
        expect(described_class.url).to eq 'https://marvin.example.com'
      end
    end
  end

  describe '.enabled?' do
    it 'is false when neither URL nor API key is set' do
      with_env('MARVINJS_URL' => nil, 'MARVINJS_API_KEY' => nil) do
        expect(described_class.enabled?).to be false
      end
    end

    it 'is true when only the URL is set' do
      with_env('MARVINJS_URL' => 'https://m.example.com', 'MARVINJS_API_KEY' => nil) do
        expect(described_class.enabled?).to be true
      end
    end

    it 'is true when only the API key is set' do
      with_env('MARVINJS_URL' => nil, 'MARVINJS_API_KEY' => 'key') do
        expect(described_class.enabled?).to be true
      end
    end
  end

  describe '.create_asset_sketch' do
    let(:params) { ActionController::Parameters.new(image: image, name: 'Benzene', description: 'Ring') }

    it 'creates a marvinjs asset attached to a step' do
      asset = nil
      expect { asset = described_class.create_asset_sketch(step, params, user, team) }.to change(Asset, :count).by(1)

      expect(asset.team).to eq team
      expect(asset.created_by).to eq user
      expect(asset.file).to be_attached
      expect(asset.file.filename.to_s).to eq 'Benzene.jpg'
      expect(asset.file.metadata).to include('name' => 'Benzene', 'description' => 'Ring', 'asset_type' => 'marvinjs')
      expect(step.reload.assets).to include(asset)
      expect(asset.view_mode).to eq step.assets_view_mode
    end

    it 'uses the default sketch name when none is given' do
      params[:name] = ''
      asset = described_class.create_asset_sketch(step, params, user, team)

      expect(asset.file.filename.to_s).to eq "#{I18n.t('marvinjs.new_sketch')}.jpg"
      expect(asset.file.metadata['name']).to eq I18n.t('marvinjs.new_sketch')
    end

    it 'attaches the asset to a result' do
      asset = described_class.create_asset_sketch(result, params, user, team)

      expect(result.reload.assets).to include(asset)
    end
  end

  describe '.create_tinymce_sketch' do
    let(:params) { ActionController::Parameters.new(image: image, name: 'Benzene', description: 'Ring') }

    it 'creates a tiny mce asset and no regular asset' do
      assets_before = Asset.count
      asset = nil
      expect { asset = described_class.create_tinymce_sketch(params, team) }.to change(TinyMceAsset, :count).by(1)
      expect(Asset.count).to eq assets_before

      expect(asset.team).to eq team
      expect(asset.image).to be_attached
      expect(asset.image.filename.to_s).to eq 'Benzene.jpg'
      expect(asset.image.metadata).to include('name' => 'Benzene', 'description' => 'Ring', 'asset_type' => 'marvinjs')
    end
  end

  describe '.update_asset_sketch' do
    let(:create_params) { ActionController::Parameters.new(image: image, name: 'Old', description: 'old') }
    let(:update_params) { ActionController::Parameters.new(image: image, name: 'New', description: 'new') }
    let(:asset) { described_class.create_asset_sketch(step, create_params, user, team) }

    it 'adds a new file version with the new metadata and updates the editor' do
      other_user = create :user
      expect { described_class.update_asset_sketch(asset, update_params, other_user) }
        .to(change { asset.reload.file.blob.id })

      asset.reload
      expect(asset.last_modified_by).to eq other_user
      expect(asset.file.filename.to_s).to eq 'New.jpg'
      expect(asset.file.metadata).to include('name' => 'New', 'description' => 'new')
    end

    it 'returns the asset' do
      expect(described_class.update_asset_sketch(asset, update_params, user)).to eq asset
    end
  end

  describe '.update_tinymce_sketch' do
    let(:create_params) { ActionController::Parameters.new(image: image, name: 'Old', description: 'old') }
    let(:tiny_asset) { described_class.create_tinymce_sketch(create_params, team) }
    let(:tiny_params) { ActionController::Parameters.new(image: image, name: 'Renamed', description: 'd') }

    it 'replaces the image and returns the tiny mce asset' do
      res = described_class.update_tinymce_sketch(tiny_asset, tiny_params)

      expect(res).to eq tiny_asset
      expect(res.reload.image.filename.to_s).to eq 'Renamed.jpg'
      expect(res.image.metadata).to include('name' => 'Renamed', 'asset_type' => 'marvinjs')
    end
  end
end
