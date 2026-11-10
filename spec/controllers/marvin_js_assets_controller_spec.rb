# frozen_string_literal: true

require 'rails_helper'

describe MarvinJsAssetsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { step: true }

  let(:image_path) { Rails.root.join('spec/fixtures/files/test.jpg') }
  let(:image) { "data:image/jpeg;base64,#{Base64.strict_encode64(File.binread(image_path))}" }
  let(:json) { JSON.parse(response.body) }
  let(:result) { create :result, my_module: my_module, user: user }

  before do
    user.update!(current_team_id: team.id)
    allow(Activities::CreateActivityService).to receive(:call)
  end

  def create_sketch_for(object, name: 'Benzene')
    params = ActionController::Parameters.new(image: image, name: name, description: 'Ring')
    MarvinJsService.create_asset_sketch(object, params, user, team)
  end

  def downgrade_to_viewer!
    UserAssignment.where(user: user).update_all(user_role_id: viewer_role.id)
  end

  describe 'POST #create' do
    let(:params) { { image: image, name: 'Benzene', description: 'Ring', object_id: step.id, object_type: 'Step' } }

    it 'creates a marvinjs asset on a step and returns rendered html' do
      expect { post :create, params: params }.to change(Asset, :count).by(1)

      asset = Asset.order(:id).last
      expect(response).to have_http_status(:ok)
      expect(json).to have_key('html')
      expect(step.reload.assets).to include(asset)
      expect(asset.file.metadata).to include('name' => 'Benzene', 'asset_type' => 'marvinjs')
    end

    it 'logs a create activity for the step' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :create_chemical_structure_on_step, owner: user, team: team))

      post :create, params: params
    end

    it 'creates a marvinjs asset on a result' do
      expect do
        post :create, params: params.merge(object_id: result.id, object_type: 'Result')
      end.to change { result.reload.assets.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(json).to have_key('html')
    end

    it 'logs a create activity for the result' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :create_chemical_structure_on_result, subject: result))

      post :create, params: params.merge(object_id: result.id, object_type: 'Result')
    end

    it 'returns 404 for an unknown object type' do
      expect { post :create, params: params.merge(object_type: 'Other') }
        .not_to change(Asset, :count)

      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for an unknown step' do
      post :create, params: params.merge(object_id: 0)

      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden when the user can only read the protocol' do
      step
      downgrade_to_viewer!

      expect { post :create, params: params }.not_to change(Asset, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden when the user can only read the result' do
      result
      downgrade_to_viewer!

      expect do
        post :create, params: params.merge(object_id: result.id, object_type: 'Result')
      end.not_to change(Asset, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden for a step of a task in another team' do
      foreign_step = create :step, protocol: create(:my_module).protocol

      post :create, params: params.merge(object_id: foreign_step.id)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT #update' do
    let!(:asset) { create_sketch_for(step) }
    let(:params) { { id: asset.id, image: image, name: 'Toluene', description: 'Methyl' } }

    it 'stores a new version and returns the preview url, id and file name' do
      put :update, params: params, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['id']).to eq asset.id
      expect(json['file_name']).to eq 'Toluene'
      expect(json['url']).to be_present
      expect(asset.reload.file.filename.to_s).to eq 'Toluene.jpg'
      expect(asset.last_modified_by).to eq user
    end

    it 'logs a finished-editing activity' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :edit_chemical_structure_on_step,
                             message_items: hash_including(action: I18n.t('activities.file_editing.finished'))))

      put :update, params: params, format: :json
    end

    it 'returns 404 for an asset of another team' do
      foreign = create :asset, team: create(:team)

      put :update, params: params.merge(id: foreign.id), format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for a viewer' do
      downgrade_to_viewer!
      put :update, params: params, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(asset.reload.file.filename.to_s).to eq 'Benzene.jpg'
    end

    it 'is forbidden for an asset not attached to anything' do
      orphan = create :asset, team: team

      put :update, params: params.merge(id: orphan.id), format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'updates a sketch on a result' do
      result_asset = create_sketch_for(result)

      put :update, params: params.merge(id: result_asset.id), format: :json

      expect(response).to have_http_status(:ok)
      expect(result_asset.reload.file.filename.to_s).to eq 'Toluene.jpg'
    end
  end

  describe 'POST #start_editing' do
    let!(:asset) { create_sketch_for(step) }

    it 'logs a started-editing activity' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :edit_chemical_structure_on_step,
                             message_items: hash_including(action: I18n.t('activities.file_editing.started'))))

      post :start_editing, params: { id: asset.id }, format: :json
    end

    it 'returns 404 for an unknown asset' do
      post :start_editing, params: { id: 0 }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for a viewer' do
      downgrade_to_viewer!
      expect(Activities::CreateActivityService).not_to receive(:call)

      post :start_editing, params: { id: asset.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
