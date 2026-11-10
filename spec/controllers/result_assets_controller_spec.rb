# frozen_string_literal: true

require 'rails_helper'

describe ResultAssetsController, type: :controller do
  include FileHelpers
  login_user

  include_context 'reference_project_structure', {
    record_deletion_enabled: true
  }

  let!(:result) { create :result, my_module: my_module, user: user, name: 'Original name' }
  let!(:result_asset) { create :result_asset, result: result }

  def downgrade_to_viewer
    UserAssignment.where(user: user, assignable: [my_module, experiment, project])
                  .update_all(user_role_id: viewer_role.id)
  end

  describe 'GET #edit' do
    it 'renders the edit form html inside json' do
      pending 'bug: edit renders an empty html string'
      get :edit, params: { id: result_asset.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['html']).to include('edit-result-asset')
    end

    it 'returns 404 for an unknown result asset' do
      get :edit, params: { id: 0 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      get :edit, params: { id: result_asset.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH #update' do
    let(:team_record) { result.my_module.experiment.project.team }

    it 'renames the result and logs an edit_result activity' do
      pending 'bug: Result has no asset method (ResultAssetsController#update raises NoMethodError)'
      allow(Activities::CreateActivityService).to receive(:call)
      patch :update, params: { id: result_asset.id, result: { name: 'New name' } }, format: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['html']).to include('New name')
      expect(result.reload.name).to eq 'New name'
      expect(result.last_modified_by).to eq user
      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: :edit_result, subject: result, owner: user)
      )
    end

    it 'redirects to the results page for html requests' do
      pending 'bug: Result has no asset method (ResultAssetsController#update raises NoMethodError)'
      patch :update, params: { id: result_asset.id, result: { name: 'New name' } }
      expect(response).to redirect_to(results_my_module_path(my_module))
      expect(flash[:success]).to eq I18n.t('result_assets.update.success_flash', module: my_module.name)
    end

    it 'replaces the file when a signed blob id is given' do
      pending 'bug: Result has no asset method (ResultAssetsController#update raises NoMethodError)'
      blob_id = create_signed_blob_id(filename: 'notes.txt', content_type: 'text/plain', content: 'hello')
      allow(Activities::CreateActivityService).to receive(:call)
      patch :update, params: { id: result_asset.id, result: { asset_attributes: { signed_blob_id: blob_id } } },
                     format: :json
      expect(response).to have_http_status(:ok)
      expect(result_asset.asset.reload.file.filename.to_s).to eq 'notes.txt'
    end

    it 'archives the result and logs an archive_result activity' do
      pending 'bug: Result has no asset method (ResultAssetsController#update raises NoMethodError)'
      allow(Activities::CreateActivityService).to receive(:call)
      patch :update, params: { id: result_asset.id, result: { archived: 'true' } }, format: :json
      expect(response).to have_http_status(:ok)
      expect(result.reload).to be_archived
      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: :archive_result, subject: result)
      )
    end

    it 'is forbidden to un-archive an archived result through this endpoint' do
      result.archive!(user)
      patch :update, params: { id: result_asset.id, result: { archived: 'false' } }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(result.reload).to be_archived
    end

    it 'refuses to archive a result whose file is locked' do
      pending 'bug: Result has no asset method (ResultAssetsController#update raises NoMethodError)'
      allow_any_instance_of(Asset).to receive(:locked?).and_return(true)
      patch :update, params: { id: result_asset.id, result: { archived: 'true' } }, format: :json
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['errors']).to have_key('asset_attributes')
      expect(result.reload).not_to be_archived
    end

    it 'refuses to edit a result whose file is locked' do
      pending 'bug: Result has no asset method (ResultAssetsController#update raises NoMethodError)'
      allow_any_instance_of(Asset).to receive(:locked?).and_return(true)
      patch :update, params: { id: result_asset.id, result: { name: 'New name' } }, format: :json
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['errors']).to have_key('asset_attributes')
      expect(result.reload.name).to eq 'Original name'
    end

    it 'returns 404 for an unknown result asset' do
      patch :update, params: { id: 0, result: { name: 'x' } }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      patch :update, params: { id: result_asset.id, result: { name: 'New name' } }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(result.reload.name).to eq 'Original name'
    end

    it 'is forbidden for archiving without manage permission' do
      downgrade_to_viewer
      patch :update, params: { id: result_asset.id, result: { archived: 'true' } }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(result.reload).not_to be_archived
    end
  end
end
