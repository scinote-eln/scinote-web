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

  describe '.create_sketch' do
    let(:params) do
      ActionController::Parameters.new(
        image: image, name: 'Benzene', description: 'Ring', object_id: step.id, object_type: 'Step'
      )
    end

    it 'creates a marvinjs asset attached to a step' do
      expect { described_class.create_sketch(params, user, team) }.to change(Asset, :count).by(1)
      asset = Asset.order(:id).last

      expect(asset.team).to eq team
      expect(asset.created_by).to eq user
      expect(asset.file).to be_attached
      expect(asset.file.filename.to_s).to eq 'Benzene.jpg'
      expect(asset.file.metadata).to include('name' => 'Benzene', 'description' => 'Ring', 'asset_type' => 'marvinjs')
      expect(step.reload.assets).to include(asset)
      expect(asset.view_mode).to eq step.assets_view_mode
    end

    it 'returns the asset and the object' do
      res = described_class.create_sketch(params, user, team)

      expect(res[:asset]).to be_a Asset
      expect(res[:object]).to eq step
    end

    it 'uses the default sketch name when none is given' do
      params[:name] = ''
      res = described_class.create_sketch(params, user, team)

      expect(res[:asset].file.filename.to_s).to eq "#{I18n.t('marvinjs.new_sketch')}.jpg"
      expect(res[:asset].file.metadata['name']).to eq I18n.t('marvinjs.new_sketch')
    end

    it 'attaches the asset to a result' do
      params[:object_type] = 'Result'
      params[:object_id] = result.id
      res = described_class.create_sketch(params, user, team)

      expect(res[:object]).to eq result
      expect(result.reload.assets).to include(res[:asset])
    end

    it 'creates a tiny mce asset for object type TinyMceAsset' do
      params[:object_type] = 'TinyMceAsset'
      assets_before = Asset.count
      res = nil
      expect { res = described_class.create_sketch(params, user, team) }.to change(TinyMceAsset, :count).by(1)
      expect(Asset.count).to eq assets_before

      asset = res[:asset]
      expect(asset.team).to eq team
      expect(asset.image).to be_attached
      expect(asset.image.metadata).to include('name' => 'Benzene', 'asset_type' => 'marvinjs')
    end
  end

  describe '.update_sketch' do
    let(:create_params) do
      ActionController::Parameters.new(image: image, name: 'Old', description: 'old', object_id: step.id,
                                       object_type: 'Step')
    end
    let(:update_params) do
      ActionController::Parameters.new(image: image, name: 'New', description: 'new', id: asset.id)
    end
    let(:asset) { described_class.create_sketch(create_params, user, team)[:asset] }

    it 'adds a new file version with the new metadata and updates the editor' do
      other_user = create :user
      expect { described_class.update_sketch(update_params, other_user, team) }
        .to(change { asset.reload.file.blob.id })

      asset.reload
      expect(asset.last_modified_by).to eq other_user
      expect(asset.file.filename.to_s).to eq 'New.jpg'
      expect(asset.file.metadata).to include('name' => 'New', 'description' => 'new')
    end

    it 'returns the asset' do
      expect(described_class.update_sketch(update_params, user, team)).to eq asset
    end

    it 'raises not found for an asset of another team' do
      update_params[:id] = asset.id
      expect { described_class.update_sketch(update_params, user, create(:team)) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'with a tiny mce asset' do
      let!(:tiny_asset) do
        described_class.create_sketch(create_params.merge(object_type: 'TinyMceAsset'), user, team)[:asset]
      end
      let(:tiny_params) do
        ActionController::Parameters.new(image: image, name: 'Renamed', description: 'd',
                                         id: Base62.encode(tiny_asset.id), object_type: 'TinyMceAsset')
      end

      it 'replaces the image and returns the tiny mce asset' do
        res = described_class.update_sketch(tiny_params, user, team)

        expect(res).to eq tiny_asset
        expect(res.reload.image.filename.to_s).to eq 'Renamed.jpg'
        expect(res.image.metadata).to include('name' => 'Renamed', 'asset_type' => 'marvinjs')
      end

      it 'raises not found for an unknown token' do
        tiny_params[:id] = Base62.encode(TinyMceAsset.maximum(:id) + 1000)
        expect { described_class.update_sketch(tiny_params, user, team) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
