# frozen_string_literal: true

require 'rails_helper'

describe AssetsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    team_role: :owner,
    result_asset: true,
    step: true,
    steps: 2,
    step_asset: true,
    result_comment: true
  }

  let(:protocol_in_repository) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:step_in_repository) { create :step, protocol: protocol_in_repository, user: user }

  let!(:asset) { create :asset }
  let(:step_asset_in_repository) { create :step_asset, step: step_in_repository, asset: asset }

  def expect_success_json
    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq('application/json')
    expect(response.body).to be_present
  end

  def expect_unprocessable_json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.media_type).to eq('application/json')
    expect(response.body).to be_present
  end

  describe 'GET #file_preview' do
    let(:action) { get :file_preview, params: { id: step_asset.asset.id }, format: :json }

    it 'file preview returned' do
      action  
      expect_success_json
    end
  end

  describe 'PATCH #toggle_view_mode' do
    let(:action) { patch :toggle_view_mode, params: { id: step_asset.asset.id, asset: {view_mode: 'inline'} }, format: :json }

    it 'change asset view mode' do
      action  
      expect_success_json
    end
  end

   describe 'GET #load_asset' do
    let(:action) { get :load_asset, params: { id: asset_id }, format: :json }

    context 'when step asset' do
      let(:asset_id) { step_asset.asset.id }
      it 'succesfully load asset' do
        action
        expect_success_json
      end
    end

    context 'when result asset' do
      let(:asset_id) { result_asset.asset.id }
      it 'succesfully load asset' do
        action
        expect_success_json
      end
    end
  end

  describe 'GET #move_targets' do
    let(:action) { get :move_targets, params: { id: asset_id }, format: :json }

    context 'when step asset' do
      let(:asset_id) { step_asset.asset.id }
      it 'succesfully load' do
        action
        expect_success_json
      end
    end

    context 'when #result asset' do
      let(:asset_id) { result_asset.asset.id }
      it 'succesfully load' do
        action
        expect_success_json
      end
    end
  end

   describe 'POST #move' do
    let(:action) { post :move, params: { id: asset_id, target_id: target_id}, format: :json }

    context 'when step asset' do
      let(:asset_id) { step_asset.asset.id }
      let(:target_id) { steps.first.id }
      it 'succesfully move' do
        action
        expect_success_json
      end
    end

    context 'when result asset' do
      let(:result1) { create :result, my_module: step.my_module, user: user }
      let(:asset_id) { result_asset.asset.id }
      let(:target_id) { result1.id }
      it 'succesfully move' do
        action
        expect_success_json
      end
    end

    context 'when protocol template asset' do
      let(:step_in_repository1) { create :step, protocol: protocol_in_repository, user: user }
      let(:asset_id) { step_asset_in_repository.asset.id }
      let(:target_id) { step_in_repository1.id }
      it 'succesfully move' do
        action
        expect_success_json
      end
    end
  end

  describe 'GET #file_url' do
    let(:action) { get :file_url, params: { id: step_asset.asset.id } }

    it 'file url returned' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'text/plain'
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET #download' do
    let(:action) { get :download, params: { id: step_asset.asset.id } }

    it 'file download url returned' do
      action  
      expect(response).to have_http_status(:redirect)
      expect(response.media_type).to eq 'text/html'
    end
  end

  describe 'GET #show' do
    let(:action) { get :show, params: { id: step_asset.asset.id } }

    it 'file show' do
      action  
      expect_success_json
    end
  end

  describe 'POST #create_wopi_file' do
    let(:action) { post :create_wopi_file, params: { element_id: element_id, element_type: element_type,
                                                     file_type: 'docx', file_name: Faker::Name.unique.name } }

    context 'when in task step' do
      let(:element_type) { 'Step' }
      let(:element_id) { step_asset.step }
      it 'create wopi file' do
        action  
        expect_success_json
      end
    end

    context 'when in task result' do
      let(:element_type) { 'Result' }
      let(:element_id) { result_asset.result }
      it 'create wopi file' do
        action  
        expect_success_json
      end
    end
  end

  describe 'PATCH #rename' do
    let(:action) { patch :rename, params: { id: element_id, asset: { name: asset_name } } }

    context 'when in task step' do
      let(:element_id) { step_asset.asset.id }
      let(:asset_name) { Faker::Name.unique.name }
      it 'rename file' do
        action  
        expect_success_json
      end
    end

    context 'when in #empty name' do
      let(:element_id) { step_asset.asset.id }
      let(:asset_name) { '' }
      it 'rename file' do
        action  
        expect_unprocessable_json
      end
    end

    context 'when to long name' do
      let(:element_id) { step_asset.asset.id }
      let(:asset_name) { Faker::Lorem.characters(number: Constants::NAME_MAX_LENGTH + 1) }
      it 'rename file' do
        action  
        expect_unprocessable_json
      end
    end

    context 'when in task result' do
      let(:element_id) { result_asset.asset.id }
      let(:asset_name) { Faker::Name.unique.name }
      it 'rename file' do
        action  
        expect_success_json
      end
    end
  end

  describe 'POST #update_image' do
    let(:action) { post :update_image, params: { id: element_id, image: fixture_file_upload(Rails.root.join('spec/fixtures/files/apple.jpg'), 'image/jpeg') } }

    context 'when in task step' do
      let(:element_id) { step_asset.asset.id }
      it 'update image' do
        action  
        expect_success_json
      end
    end

    context 'when in task result' do
      let(:element_id) { result_asset.asset.id }
      it 'update image' do
        action  
        expect_success_json
      end
    end
  end

  describe 'GET #versions' do
    let(:action) { get :versions, params: { id: step_asset.asset.id } }

    it 'file versions returned' do
      action  
      expect_success_json
    end
  end

  describe 'GET #checksum' do
    let(:action) { get :checksum, params: { id: step_asset.asset.id } }

    it 'checksum returned' do
      action  
      expect_success_json
    end
  end

  describe 'POST #duplicate' do
    let(:action) { post :duplicate, params: { id: element_id } }

    context 'when in task step' do
      let(:element_id) { step_asset.asset.id }
      it 'duplicate' do
        action  
        expect_success_json
      end
    end

    context 'when in task result' do
      let(:element_id) { result_asset.asset.id }
      it 'duplicate' do
        action  
        expect_success_json
      end
    end
  end

  describe 'POST #restore_version' do
    let(:action) { post :restore_version, params: { id: element_id, version: 1 } }

    before do
      allow_any_instance_of(Asset).to receive(:restore_file_version).and_return(true)
    end

    context 'when in task step' do
      let(:element_id) { step_asset.asset.id }
      it 'restore version' do
        action  
        expect_success_json
      end
    end

    context 'when in task result' do
      let(:element_id) { result_asset.asset.id }
      it 'restore version' do
        action  
        expect_success_json
      end
    end

    context 'when in protocol' do
      let(:element_id) { step_asset_in_repository.asset.id }
      it 'restore version' do
        action  
        expect_success_json
      end
    end
  end


  describe 'POST #start_edit' do
    before do
      allow(controller).to receive(:check_manage_permission).and_return(true)
    end
    let(:action) { post :create_start_edit_image_activity, params: params, format: :json }
    let!(:params) do
      { id: nil }
    end
    it 'calls create activity service (start edit image on step)' do
      params[:id] = step_asset.asset.id
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :edit_image_on_step))
      action
    end

    it 'calls create activity service (start edit image on result)' do
      params[:id] = result_asset.asset.id
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :edit_image_on_result))
      action
    end

    it 'calls create activity service (start edit image on step in repository)' do
      params[:id] = step_asset_in_repository.asset.id
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :edit_image_on_step_in_repository))
      action
    end

    it 'adds activity in DB' do
      params[:id] = step_asset.asset.id
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'DELETE #destroy' do
    let(:action) { delete :destroy, params: { id: element_id } }

    context 'when in task step' do
      let(:element_id) { step_asset.asset.id }
      it 'destroy' do
        action  
        expect_success_json
      end
    end

    context 'when in task result' do
      let(:element_id) { result_asset.asset.id }
      it 'destroy' do
        action  
        expect_success_json
      end
    end
  end
end
