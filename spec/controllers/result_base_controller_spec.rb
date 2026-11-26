# frozen_string_literal: true

require 'rails_helper'

# ResultBaseController is abstract; its shared actions are exercised through
# ResultsController (task results) and ResultTemplatesController (protocol templates).
describe ResultsController, type: :controller do
  include FileHelpers
  login_user

  include_context 'reference_project_structure', {
    record_deletion_enabled: true
  }

  let!(:result) { create :result, my_module: my_module, user: user, name: 'Bravo result' }

  def downgrade_to_viewer
    UserAssignment.where(user: user, assignable: [my_module, experiment, project])
                  .update_all(user_role_id: viewer_role.id)
  end

  describe 'GET #index' do
    let!(:older_result) do
      create :result, my_module: my_module, user: user, name: 'Alpha result', created_at: 2.days.ago
    end

    it 'renders the html page' do
      get :index, params: { my_module_id: my_module.id }
      expect(response).to have_http_status(:ok)
      expect(assigns(:active_tab)).to eq :results
    end

    it 'returns active results ordered by default (created_at desc)' do
      get :index, params: { my_module_id: my_module.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data'].map { |r| r['id'].to_i }).to eq [result.id, older_result.id]
      expect(response.parsed_body.dig('meta', 'sort')).to eq 'created_at_desc'
    end

    it 'stores and applies the requested sort order' do
      get :index, params: { my_module_id: my_module.id, sort: 'name_asc' }, format: :json
      expect(response.parsed_body['data'].map { |r| r['id'].to_i }).to eq [older_result.id, result.id]
      setting = user.user_settings.find_by(key: 'results_order')
      expect(setting.value[my_module.id.to_s]).to eq 'name_asc'

      get :index, params: { my_module_id: my_module.id }, format: :json
      expect(response.parsed_body.dig('meta', 'sort')).to eq 'name_asc'
    end

    %w(name_desc created_at_asc updated_at_asc updated_at_desc).each do |sort|
      it "accepts #{sort} sort" do
        get :index, params: { my_module_id: my_module.id, sort: sort }, format: :json
        expect(response.parsed_body.dig('meta', 'sort')).to eq sort
        expect(response.parsed_body['data'].size).to eq 2
      end
    end

    it 'sorts name descending' do
      get :index, params: { my_module_id: my_module.id, sort: 'name_desc' }, format: :json
      expect(response.parsed_body['data'].map { |r| r['id'].to_i }).to eq [result.id, older_result.id]
    end

    it 'filters by created_at range' do
      get :index, params: { my_module_id: my_module.id,
                            created_at_from: 1.day.ago.iso8601,
                            created_at_to: 1.minute.from_now.iso8601 }, format: :json
      expect(response.parsed_body['data'].map { |r| r['id'].to_i }).to eq [result.id]
    end

    it 'filters by updated_at range' do
      older_result.update_column(:updated_at, 3.days.ago)
      get :index, params: { my_module_id: my_module.id,
                            updated_at_from: 1.day.ago.iso8601,
                            updated_at_to: 1.minute.from_now.iso8601 }, format: :json
      expect(response.parsed_body['data'].map { |r| r['id'].to_i }).to eq [result.id]
    end

    it 'filters by search query' do
      get :index, params: { my_module_id: my_module.id, query: 'Alpha' }, format: :json
      expect(response.parsed_body['data'].map { |r| r['id'].to_i }).to eq [older_result.id]
    end

    it 'lists archived results in archived view mode with separate sort preference' do
      archived = create :result, :archived, my_module: my_module, user: user
      get :index, params: { my_module_id: my_module.id, view_mode: 'archived', sort: 'name_asc' }, format: :json
      expect(response.parsed_body['data'].map { |r| r['id'].to_i }).to eq [archived.id]
      expect(user.user_settings.find_by(key: 'results_order_archived').value[my_module.id.to_s]).to eq 'name_asc'
    end

    it 'raises not found when the user cannot read the task' do
      UserAssignment.where(user: user, assignable: [my_module, experiment, project]).destroy_all
      expect do
        get :index, params: { my_module_id: my_module.id }, format: :json
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST #create' do
    it 'creates a result and logs activity' do
      expect do
        post :create, params: { my_module_id: my_module.id }, format: :json
      end.to change(Result, :count).by(1).and change(Activity, :count).by(1)
      new_result = Result.order(:id).last
      expect(response.parsed_body.dig('data', 'id').to_i).to eq new_result.id
      expect(new_result.user).to eq user
      expect(Activity.last.type_of).to eq 'add_result'
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      expect do
        post :create, params: { my_module_id: my_module.id }, format: :json
      end.not_to change(Result, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH #update' do
    it 'renames the result and logs edit activity' do
      patch :update, params: { my_module_id: my_module.id, id: result.id, result: { name: 'Renamed' } },
                     format: :json
      expect(response).to have_http_status(:ok)
      expect(result.reload.name).to eq 'Renamed'
      expect(result.last_modified_by).to eq user
      expect(Activity.last.type_of).to eq 'edit_result'
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      patch :update, params: { my_module_id: my_module.id, id: result.id, result: { name: 'Renamed' } },
                     format: :json
      expect(response).to have_http_status(:forbidden)
      expect(result.reload.name).to eq 'Bravo result'
    end
  end

  describe 'GET #elements' do
    let!(:text_element) { create :result_orderable_element, :result_text, result: result, position: 0 }
    let!(:table_element) { create :result_orderable_element, :result_table, result: result, position: 1 }

    it 'returns serialized active elements in order' do
      get :elements, params: { my_module_id: my_module.id, id: result.id }, format: :json
      types = response.parsed_body['data'].map { |e| e['type'] }
      expect(types).to eq %w(ResultText Table)
    end

    it 'returns archived elements in archived view mode' do
      text_element.orderable.update!(archived: true)
      get :elements, params: { my_module_id: my_module.id, id: result.id, view_mode: 'archived' }, format: :json
      ids = response.parsed_body['data'].map { |e| e['id'] }
      expect(ids).to eq [text_element.orderable.id]
    end

    it 'is forbidden without read access' do
      allow(controller).to receive(:can_read_result?).and_return(false)
      get :elements, params: { my_module_id: my_module.id, id: result.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST #upload_attachment' do
    let(:signed_blob_id) do
      create_signed_blob_id(filename: 'notes.txt', content_type: 'text/plain', content: 'hello')
    end

    it 'attaches a file to the result and logs activity' do
      expect do
        post :upload_attachment, params: { my_module_id: my_module.id, id: result.id, signed_blob_id: signed_blob_id },
                                 format: :json
      end.to change { result.assets.count }.by(1)
      expect(response.parsed_body.dig('data', 'attributes', 'file_name')).to eq 'notes.txt'
      expect(Activity.last.type_of).to eq 'result_file_added'
    end

    it 'is forbidden when attachments are locked' do
      result.update!(attachments_locked: true)
      post :upload_attachment, params: { my_module_id: my_module.id, id: result.id, signed_blob_id: signed_blob_id },
                               format: :json
      expect(response).to have_http_status(:forbidden)
      expect(result.assets.count).to eq 0
    end
  end

  describe 'POST #update_view_state' do
    it 'stores the asset sort order' do
      post :update_view_state, params: { my_module_id: my_module.id, id: result.id, assets: { order: 'atoz' } },
                               format: :json
      expect(response).to have_http_status(:ok)
      expect(result.current_view_state(user).state.dig('assets', 'sort')).to eq 'atoz'
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      post :update_view_state, params: { my_module_id: my_module.id, id: result.id, assets: { order: 'atoz' } },
                               format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST #update_asset_view_mode' do
    it 'updates view mode of the result and its assets' do
      result_asset = create :result_asset, result: result
      post :update_asset_view_mode, params: { my_module_id: my_module.id, id: result.id, assets_view_mode: 'list' },
                                    format: :json
      expect(response.parsed_body['view_mode']).to eq 'list'
      expect(result.reload.assets_view_mode).to eq 'list'
      expect(result_asset.asset.reload.view_mode).to eq 'list'
    end

    it 'returns unprocessable entity when the result is invalid' do
      allow_any_instance_of(Result).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(result))
      post :update_asset_view_mode, params: { my_module_id: my_module.id, id: result.id, assets_view_mode: 'list' },
                                    format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to be_present
    end
  end

  describe 'DELETE #destroy' do
    it 'discards an archived result and logs activity' do
      result.archive!(user)
      delete :destroy, params: { my_module_id: my_module.id, id: result.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(Result.with_discarded.find(result.id)).to be_discarded
      expect(Activity.last.type_of).to eq 'destroy_result'
    end

    it 'is forbidden for active results' do
      delete :destroy, params: { my_module_id: my_module.id, id: result.id }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(result.reload).not_to be_discarded
    end

    it 'returns errors when discard fails' do
      result.archive!(user)
      allow_any_instance_of(Result).to receive(:discard).and_return(false)
      delete :destroy, params: { my_module_id: my_module.id, id: result.id }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #duplicate' do
    it 'creates a copy and logs activity' do
      expect do
        post :duplicate, params: { my_module_id: my_module.id, id: result.id }, format: :json
      end.to change(Result, :count).by(1)
      expect(response.parsed_body.dig('data', 'attributes', 'name')).to eq 'Bravo result (1)'
      expect(Activity.last.type_of).to eq 'result_duplicated'
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      expect do
        post :duplicate, params: { my_module_id: my_module.id, id: result.id }, format: :json
      end.not_to change(Result, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end

describe ResultTemplatesController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:result_template) { create :result_template, protocol: protocol, user: user }
  let!(:other_template) { create :result_template, protocol: protocol, user: user }

  describe 'POST #change_results_state' do
    it 'stores collapsed state for every template of the protocol' do
      post :change_results_state, params: { protocol_id: protocol.id, collapsed: true }, format: :json
      expect(response).to have_http_status(:ok)
      setting = user.user_settings.find_by(key: 'result_template_states')
      expect(setting.value).to eq(result_template.id.to_s => true, other_template.id.to_s => true)
    end

    it 'stores expanded state when collapsed param is absent' do
      post :change_results_state, params: { protocol_id: protocol.id }, format: :json
      setting = user.user_settings.find_by(key: 'result_template_states')
      expect(setting.value.values).to all(be false)
    end
  end

  describe 'DELETE #destroy' do
    it 'logs protocol in activity message items' do
      delete :destroy, params: { protocol_id: protocol.id, id: result_template.id }, format: :json
      activity = Activity.last
      expect(activity.type_of).to eq 'destroy_result_template'
      expect(activity.values.dig('message_items', 'protocol', 'id')).to eq protocol.id
    end
  end

  describe 'GET #index' do
    it 'returns templates as json' do
      get :index, params: { protocol_id: protocol.id }, format: :json
      expect(response.parsed_body['data'].map { |r| r['id'].to_i }).to contain_exactly(result_template.id,
                                                                                         other_template.id)
    end
  end
end
