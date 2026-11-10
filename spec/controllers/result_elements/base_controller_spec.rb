# frozen_string_literal: true

require 'rails_helper'

# ResultElements::BaseController is abstract; its shared actions are exercised through
# ResultElements::TextsController, for a task result and for a protocol result template.
describe ResultElements::TextsController, type: :controller do
  login_user

  def activity_count(type)
    Activity.where(type_of: type).count
  end

  context 'with a task result' do
    include_context 'reference_project_structure', { record_deletion_enabled: true }

    let!(:result) { create :result, my_module: my_module, user: user }
    let!(:other_result) { create :result, my_module: my_module, user: user, name: 'Other result' }
    let!(:archived_result) { create :result, :archived, my_module: my_module, user: user }
    let!(:result_text) { create :result_text, result: result }
    let!(:orderable_element) do
      create :result_orderable_element, result: result, orderable: result_text, position: 0
    end

    def downgrade_to_viewer
      UserAssignment.where(user: user, assignable: [my_module, experiment, project])
                    .update_all(user_role_id: viewer_role.id)
    end

    describe 'GET move_targets' do
      it 'lists the other active results of the task' do
        get :move_targets, params: { result_id: result.id, id: result_text.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['targets']).to eq [[other_result.id, other_result.name]]
      end

      it 'returns 404 for an unknown result' do
        get :move_targets, params: { result_id: 0, id: result_text.id }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'is forbidden for viewers' do
        downgrade_to_viewer
        get :move_targets, params: { result_id: result.id, id: result_text.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST create' do
      it 'creates a text and logs a task result activity' do
        expect { post :create, params: { result_id: result.id }, format: :json }
          .to change { result.result_texts.count }.by(1)
          .and change { activity_count(:result_text_added) }.by(1)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'POST archive' do
      it 'archives the text and logs an activity' do
        expect { post :archive, params: { result_id: result.id, id: result_text.id }, format: :json }
          .to change { activity_count(:result_text_archived) }.by(1)
        expect(response).to have_http_status(:ok)
        expect(result_text.reload).to be_archived
        expect(result_text.archived_by).to eq user
      end

      it 'renders the error when archiving fails' do
        allow_any_instance_of(ResultText).to receive(:archive!).and_raise(ActiveRecord::RecordInvalid)
        post :archive, params: { result_id: result.id, id: result_text.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to be_present
        expect(result_text.reload).not_to be_archived
      end

      it 'is forbidden for viewers' do
        downgrade_to_viewer
        post :archive, params: { result_id: result.id, id: result_text.id }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result_text.reload).not_to be_archived
      end
    end

    describe 'POST restore' do
      before { result_text.archive!(user) }

      it 'restores the text, logs an activity and returns the restore message' do
        expect { post :restore, params: { result_id: result.id, id: result_text.id }, format: :json }
          .to change { activity_count(:result_text_restored) }.by(1)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['message']).to eq I18n.t('protocols.steps.modals.restore_modal.restore_text')
        expect(result_text.reload).not_to be_archived
        expect(result_text.restored_by).to eq user
      end

      it 'renders the error when restoring fails' do
        allow_any_instance_of(ResultText).to receive(:restore!).and_raise(ActiveRecord::RecordInvalid)
        post :restore, params: { result_id: result.id, id: result_text.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to be_present
        expect(result_text.reload).to be_archived
      end

      it 'is forbidden for viewers' do
        downgrade_to_viewer
        post :restore, params: { result_id: result.id, id: result_text.id }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result_text.reload).to be_archived
      end
    end

    describe 'POST lock and unlock' do
      it 'is forbidden for task results because locking is template-only' do
        post :lock, params: { result_id: result.id, id: result_text.id }, format: :json
        expect(response).to have_http_status(:forbidden)
        post :unlock, params: { result_id: result.id, id: result_text.id }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result_text.reload.locked).to be false
      end
    end
  end

  context 'with a result template' do
    let!(:user) { subject.current_user }
    let!(:team) { create :team, :record_deletion_enabled, created_by: user }
    let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
    let!(:result_template) { create :result_template, protocol: protocol, user: user }
    let!(:other_template) { create :result_template, protocol: protocol, user: user }
    let!(:result_text) { create :result_text, result: result_template }
    let!(:orderable_element) do
      create :result_orderable_element, result: result_template, orderable: result_text, position: 0
    end
    let(:params) { { result_id: result_template.id, id: result_text.id } }

    it 'lists the other templates as move targets' do
      get :move_targets, params: params, format: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['targets'].map(&:first)).to include(other_template.id)
      expect(response.parsed_body['targets'].map(&:first)).not_to include(result_template.id)
    end

    it 'switches the current team to the protocol team' do
      pending 'bug: ResultElements::BaseController calls current_team_switch without including TeamsHelper'
      other_team = create :team, created_by: user
      user.update!(current_team_id: other_team.id)
      get :move_targets, params: params, format: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.current_team_id).to eq team.id
    end

    it 'archives the text and logs a result template activity' do
      # can_archive_result_text? is hard-wired to false for ResultTemplate texts (it requires result.is_a?(Result)),
      # so the template branch of #archive can only be reached with this one stub.
      without_partial_double_verification { allow(controller).to receive(:can_archive_result_text?).and_return(true) }
      allow(Activities::CreateActivityService).to receive(:call)
      post :archive, params: params, format: :json
      expect(response).to have_http_status(:ok)
      expect(result_text.reload).to be_archived
      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: :result_template_text_archived, subject: result_template, project: nil,
                       team: team,
                       message_items: hash_including(:protocol => protocol.id, 'result_template' => result_template.id))
      )
    end

    it 'restores the text' do
      result_text.archive!(user)
      allow(Activities::CreateActivityService).to receive(:call)
      post :restore, params: params, format: :json
      expect(response).to have_http_status(:ok)
      expect(result_text.reload).not_to be_archived
      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: :result_template_text_restored)
      )
    end

    context 'when the user only has the viewer role on the protocol' do
      let(:viewer) { create(:user).tap(&:confirm) }

      before do
        viewer_role = UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role)
        create :user_assignment, assignable: team, user: viewer, user_role: viewer_role, assigned_by: user
        create_user_assignment(protocol, viewer_role, viewer, user)
        viewer.update!(current_team_id: team.id)
        allow(Protocol).to receive(:content_locking_enabled?).and_return(true)
        sign_out user
        sign_in viewer
      end

      it 'forbids archiving' do
        post :archive, params: params, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result_text.reload).not_to be_archived
      end

      it 'forbids restoring' do
        result_text.archive!(user)
        post :restore, params: params, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result_text.reload).to be_archived
      end

      it 'forbids locking' do
        post :lock, params: params, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result_text.reload.locked).to be false
      end

      it 'forbids unlocking' do
        result_text.update!(locked: true)
        post :unlock, params: params, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(result_text.reload.locked).to be true
      end
    end

    it 'responds with 422 when locking fails validation' do
      allow(Protocol).to receive(:content_locking_enabled?).and_return(true)
      allow_any_instance_of(ResultText).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      post :lock, params: params, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(result_text.reload.locked).to be false
    end

    it 'responds with 422 when unlocking fails validation' do
      allow(Protocol).to receive(:content_locking_enabled?).and_return(true)
      result_text.update!(locked: true)
      allow_any_instance_of(ResultText).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      post :unlock, params: params, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(result_text.reload.locked).to be true
    end
  end
end
