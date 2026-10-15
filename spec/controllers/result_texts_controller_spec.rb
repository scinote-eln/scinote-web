# frozen_string_literal: true

require 'rails_helper'

# ResultTextsController is the legacy controller; only #download is routed, so
# #edit and #update are exercised through temporarily drawn routes.
describe ResultTextsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { record_deletion_enabled: true }

  let!(:result) { create :result, my_module: my_module, user: user, name: 'Result one' }
  let!(:result_text) { create :result_text, result: result, text: 'Hello text' }

  def downgrade_to_viewer
    UserAssignment.where(user: user, assignable: [my_module, experiment, project])
                  .update_all(user_role_id: viewer_role.id)
  end

  def draw_routes(&block)
    set = ActionDispatch::Routing::RouteSet.new
    original_routes = @routes
    begin
      set.draw do
        get 'result_texts/:id/download', to: 'result_texts#download', as: :result_text_download
        resources :result_texts, only: %i(edit update)
        get 'projects/:id', to: 'projects#show', as: :project
        get 'experiments/:id/my_modules', to: 'experiments#my_modules', as: :my_modules_experiment
        get 'my_modules/:id/protocols', to: 'my_modules#protocols', as: :protocols_my_module
        get 'my_modules/:id/results', to: 'my_modules#results', as: :results_my_module
      end
      @routes = set
      instance_exec(&block)
    ensure
      @routes = original_routes
    end
  end

  describe 'GET #download' do
    it 'sends the text as a txt attachment named after the result' do
      draw_routes do
        get :download, params: { id: result_text.id }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq 'Hello text'
        expect(response.headers['Content-Disposition']).to include('Result one.txt')
        expect(response.media_type).to eq 'plain/text'
      end
    end

    it 'returns 404 for an unknown text' do
      draw_routes do
        get :download, params: { id: 0 }
        expect(response).to have_http_status(:not_found)
      end
    end

    it 'returns forbidden when the user cannot read the result' do
      draw_routes do
        without_partial_double_verification do
          allow(controller).to receive(:can_read_result?).and_return(false)
        end
        get :download, params: { id: result_text.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #edit' do
    render_views

    it 'returns forbidden when the user cannot manage the result' do
      draw_routes do
        downgrade_to_viewer
        get :edit, params: { id: result_text.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'returns 404 for an unknown text' do
      draw_routes do
        get :edit, params: { id: 0 }
        expect(response).to have_http_status(:not_found)
      end
    end

    it 'renders the edit form html' do
      pending 'bug: edit partial calls Result#result_text which no longer exists'
      draw_routes do
        get :edit, params: { id: result_text.id }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['html']).to include('edit-text-result')
      end
    end
  end

  describe 'PUT #update' do
    before do
      allow(Activities::CreateActivityService).to receive(:call)
      allow(TinyMceAsset).to receive(:update_images)
    end

    it 'renames the result, logs an edit activity and answers json' do
      pending 'bug: my_modules/_result partial does not exist (MissingTemplate)'
      draw_routes do
        put :update, params: { id: result_text.id, result: { name: 'Renamed' } }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to have_key('html')
        expect(result.reload.name).to eq 'Renamed'
        expect(result.last_modified_by).to eq user
        expect(Activities::CreateActivityService).to have_received(:call).with(
          hash_including(activity_type: :edit_result, subject: result,
                         message_items: { result: result.id, type_of_result: I18n.t('activities.result_type.text') })
        )
        expect(TinyMceAsset).to have_received(:update_images).with(result_text, nil, user)
      end
    end

    it 'redirects with a flash for html requests' do
      pending 'bug: results_my_module_path is not defined (NoMethodError); route is my_module_results_path'
      draw_routes do
        put :update, params: { id: result_text.id, result: { name: 'Renamed' } }
        expect(response).to redirect_to("/my_modules/#{my_module.id}/results")
        expect(flash[:success]).to eq I18n.t('result_texts.update.success_flash', module: my_module.name)
      end
    end

    it 'archives the result and logs an archive activity' do
      pending 'bug: my_modules/_result partial does not exist (MissingTemplate)'
      draw_routes do
        put :update, params: { id: result_text.id, result: { archived: 'true' } }, format: :json
        expect(response).to have_http_status(:ok)
        expect(result.reload.archived).to be true
        expect(Activities::CreateActivityService).to have_received(:call).with(
          hash_including(activity_type: :archive_result)
        )
      end
    end

    it 'returns bad request with errors when the name is too long' do
      draw_routes do
        put :update, params: { id: result_text.id,
                               result: { name: 'a' * (Constants::NAME_MAX_LENGTH + 1) } }, format: :json
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to have_key('name')
      end
    end

    it 'returns forbidden when restoring through update' do
      result.update!(archived: true, archived_on: Time.zone.now, archived_by: user)
      draw_routes do
        put :update, params: { id: result_text.id, result: { archived: 'false' } }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'returns forbidden for a viewer' do
      draw_routes do
        downgrade_to_viewer
        put :update, params: { id: result_text.id, result: { name: 'Nope' } }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result.reload.name).to eq 'Result one'
      end
    end

    it 'updates the text through result_text_attributes' do
      pending 'bug: Result has no result_text_attributes= (update_params cannot assign the text)'
      draw_routes do
        put :update, params: { id: result_text.id,
                               result: { result_text_attributes: { id: result_text.id, text: 'New body' } } },
                     format: :json
        expect(response).to have_http_status(:ok)
        expect(result_text.reload.text).to eq 'New body'
      end
    end
  end
end
