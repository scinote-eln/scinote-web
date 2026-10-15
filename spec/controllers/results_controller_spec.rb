# frozen_string_literal: true

require 'rails_helper'

describe ResultsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    result_text: true,
    record_deletion_enabled: true
  }

  describe 'DELETE destroy' do

    let(:action) { delete :destroy, params: params }
    let(:params) do
      {
        my_module_id: result_text.result.my_module.id,
        id: result_text.result.id
      }
    end

    before do
      result_text.result.archive!(user)
    end

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :destroy_result))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    it 'destroys the result' do
      expect { action }.to change { Result.where(id: result_text.result.id).count }.from(1).to(0)
      expect(response).to have_http_status(:ok)
    end

    context 'when the user only has the viewer role' do
      before do
        UserAssignment.where(user: user, assignable: [my_module, experiment, project])
                      .update_all(user_role_id: viewer_role.id)
      end

      it 'is forbidden and destroys nothing' do
        expect(Activities::CreateActivityService).not_to receive(:call)
        expect { action }.not_to(change { [Result.count, ResultText.count, Activity.count] })
        expect(response).to have_http_status(:forbidden)
        expect(Result.exists?(result_text.result.id)).to be true
      end
    end
  end

  context 'with plain results' do
    render_views

    let!(:result) { create :result, my_module: my_module, user: user, name: 'Alpha' }
    let!(:other_result) { create :result, my_module: my_module, user: user, name: 'Beta' }
    let!(:archived_result) { create :result, :archived, my_module: my_module, user: user, name: 'Gamma' }
    let(:base_params) { { my_module_id: my_module.id, id: result.id } }

    def downgrade_to_viewer
      UserAssignment.where(user: user, assignable: [my_module, experiment, project])
                    .update_all(user_role_id: viewer_role.id)
    end

    describe 'GET list' do
      it 'returns only active results' do
        get :list, params: { my_module_id: my_module.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.map(&:first)).to contain_exactly(result.id, other_result.id)
      end

      it 'includes results linked to the given step even when archived' do
        step = create :step, protocol: my_module.protocol, user: user
        create :step_result, step: step, result: archived_result, created_by: user
        get :list, params: { my_module_id: my_module.id, with_linked_step_id: step.id }, format: :json
        expect(response.parsed_body.map(&:first))
          .to contain_exactly(result.id, other_result.id, archived_result.id)
      end

      it 'stores the archived sort preference under its own key' do
        get :list, params: { my_module_id: my_module.id, view_mode: 'archived', sort: 'name_asc' }, format: :json
        setting = user.user_settings.find_by(key: 'results_order_archived')
        expect(setting.value[my_module.id.to_s]).to eq 'name_asc'
      end

      it 'returns 404 for a task the user cannot read' do
        pending 'bug: unreadable task raises ActiveRecord::RecordNotFound instead of rendering 404'
        get :list, params: { my_module_id: 0 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'POST pin and unpin' do
      it 'pins the result for the current user' do
        post :pin, params: base_params, format: :json
        expect(response).to have_http_status(:ok)
        expect(result.reload).to be_pinned
        expect(result.pinned_by).to eq user
      end

      it 'unpins a pinned result' do
        result.pin!(user)
        post :unpin, params: base_params, format: :json
        expect(response).to have_http_status(:ok)
        expect(result.reload).not_to be_pinned
        expect(result.pinned_by).to be_nil
      end

      it 'is forbidden for viewers' do
        downgrade_to_viewer
        post :pin, params: base_params, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result.reload).not_to be_pinned
      end

      it 'is forbidden to unpin for viewers' do
        result.pin!(user)
        downgrade_to_viewer
        post :unpin, params: base_params, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result.reload).to be_pinned
      end
    end

    describe 'POST archive' do
      it 'archives and unpins the result and logs an activity' do
        result.pin!(user)
        allow(Activities::CreateActivityService).to receive(:call)
        post :archive, params: base_params, format: :json
        expect(response).to have_http_status(:ok)
        expect(result.reload).to be_archived
        expect(result.archived_by).to eq user
        expect(result).not_to be_pinned
        expect(Activities::CreateActivityService).to have_received(:call).with(
          hash_including(activity_type: :archive_result, subject: result)
        )
      end

      it 'renders the validation errors when archiving fails' do
        allow_any_instance_of(Result).to receive(:archive!) do |r|
          r.errors.add(:base, 'cannot archive')
          raise ActiveRecord::RecordInvalid, r
        end
        post :archive, params: base_params, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include('cannot archive')
        expect(result.reload).not_to be_archived
      end

      it 'is forbidden for viewers' do
        downgrade_to_viewer
        post :archive, params: base_params, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result.reload).not_to be_archived
      end
    end

    describe 'POST restore' do
      let(:restore_params) { { my_module_id: my_module.id, id: archived_result.id } }

      it 'restores the result, logs an activity and returns an empty body' do
        allow(Activities::CreateActivityService).to receive(:call)
        post :restore, params: restore_params, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({})
        expect(archived_result.reload).not_to be_archived
        expect(archived_result.restored_by).to eq user
        expect(Activities::CreateActivityService).to have_received(:call).with(
          hash_including(activity_type: :result_restored, subject: archived_result)
        )
      end

      it 'returns the serialized result when archived elements remain' do
        text = create :result_text, result: archived_result, archived: true
        post :restore, params: restore_params, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig('data', 'id').to_i).to eq archived_result.id
        expect(text.reload).to be_archived
      end

      it 'responds with 422 when the result cannot be restored' do
        allow_any_instance_of(Result).to receive(:restore) do |r|
          r.errors.add(:base, 'cannot restore')
          false
        end
        post :restore, params: restore_params, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include('cannot restore')
      end

      it 'is forbidden for viewers' do
        downgrade_to_viewer
        post :restore, params: restore_params, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(archived_result.reload).to be_archived
      end
    end

    describe 'GET assets' do
      let!(:active_asset) { create :result_asset, result: result }
      let!(:archived_asset) { create :result_asset, result: result }

      before { archived_asset.asset.update!(archived: true) }

      it 'returns the active assets of the result' do
        get :assets, params: base_params, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['data'].map { |a| a['id'].to_i }).to eq [active_asset.asset.id]
      end

      it 'returns the archived assets in archived view mode' do
        get :assets, params: base_params.merge(view_mode: 'archived'), format: :json
        expect(response.parsed_body['data'].map { |a| a['id'].to_i }).to eq [archived_asset.asset.id]
      end

      it 'is forbidden without read permission' do
        allow(controller).to receive(:can_read_result?).and_return(false)
        get :assets, params: base_params, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
