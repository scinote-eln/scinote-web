# frozen_string_literal: true

require 'rails_helper'

describe StepElements::ChecklistsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:step) { create :step, protocol: protocol }
  let!(:checklist) { create :checklist, step: step }

  describe 'POST lock' do
    let(:action) { post :lock, params: { step_id: step.id, id: checklist.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_lock_step_checklist?).and_return(true) }

      it 'locks the checklist' do
        action
        expect(response).to have_http_status(:ok)
        expect(checklist.reload.locked).to be true
      end

      it 'logs a lock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: 'lock_protocol_step_checklist')))
        action
      end

      it 'does not log an activity when the checklist is already locked' do
        checklist.update!(locked: true)
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService).not_to have_received(:call)
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_lock_step_checklist?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST unlock' do
    before { checklist.update!(locked: true) }

    let(:action) { post :unlock, params: { step_id: step.id, id: checklist.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_unlock_step_checklist?).and_return(true) }

      it 'unlocks the checklist' do
        action
        expect(response).to have_http_status(:ok)
        expect(checklist.reload.locked).to be false
      end

      it 'logs an unlock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: 'unlock_protocol_step_checklist')))
        action
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_unlock_step_checklist?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'repository protocol steps' do
    let!(:other_step) { create :step, protocol: protocol }
    let!(:element_checklist) { create(:step_orderable_element, step: step, orderable: create(:checklist, step: step)).orderable }

    it 'creates and logs a protocol_step activity' do
      allow(Activities::CreateActivityService).to receive(:call)
      expect { post :create, params: { step_id: step.id }, format: :json }
        .to change { step.checklists.count }.by(1)
      expect(response).to have_http_status(:ok)
      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: 'protocol_step_checklist_added', subject: protocol, project: nil)
      )
    end

    it 'deletes the element directly and logs a protocol_step activity' do
      allow(Activities::CreateActivityService).to receive(:call)
      expect { delete :destroy, params: { step_id: step.id, id: element_checklist.id }, format: :json }
        .to change { step.checklists.count }.by(-1)
      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: 'protocol_step_checklist_deleted')
      )
    end

    it 'returns 404 when deleting an unknown element' do
      delete :destroy, params: { step_id: step.id, id: 0 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden to delete without delete permission' do
      allow(controller).to receive(:can_delete_step_checklist?).and_return(false)
      expect { delete :destroy, params: { step_id: step.id, id: element_checklist.id }, format: :json }
        .not_to change { step.checklists.count }
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden to archive in repository protocols' do
      post :archive, params: { step_id: step.id, id: element_checklist.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden to move without manage permission' do
      allow(controller).to receive(:can_manage_step_checklist?).and_return(false)
      post :move, params: { step_id: step.id, id: element_checklist.id, target_id: other_step.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'restores an archived element of a repository protocol' do
      pending 'bug: log_step_restore_activity dereferences protocol.my_module, which is nil outside tasks'
      element_checklist.update!(archived: true, archived_by: user, archived_on: Time.zone.now)
      post :restore, params: { step_id: step.id, id: element_checklist.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(element_checklist.reload).not_to be_archived
    end

    it 'duplicates after the original' do
      expect { post :duplicate, params: { step_id: step.id, id: element_checklist.id }, format: :json }
        .to change { step.checklists.count }.by(1)
      expect(response).to have_http_status(:ok)
    end
  end
end

# Real permission checks on a task (my_module) step; the block above stubs permissions on a repository protocol.
describe StepElements::ChecklistsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    record_deletion_enabled: true,
    step: true
  }

  let!(:other_step) { create :step, protocol: my_module.protocol, user: user }
  let!(:element_checklist) do
    create(:step_orderable_element, step: step, orderable: create(:checklist, step: step)).orderable
  end
  let(:base_params) { { step_id: step.id, id: element_checklist.id } }

  def downgrade_to_viewer
    UserAssignment.where(user: user, assignable: [my_module, experiment, project])
                  .update_all(user_role_id: viewer_role.id)
  end

  def activity_count(type)
    Activity.where(type_of: type).count
  end

  describe 'GET move_targets' do
    it 'lists the other active steps of the protocol' do
      get :move_targets, params: base_params, format: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['targets']).to eq [[other_step.id, other_step.name]]
    end

    it 'excludes archived steps' do
      other_step.update!(archived: true, archived_by: user, archived_on: Time.zone.now)
      get :move_targets, params: base_params, format: :json
      expect(response.parsed_body['targets']).to eq []
    end

    it 'returns 404 for an unknown step' do
      get :move_targets, params: { step_id: 0, id: element_checklist.id }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      get :move_targets, params: base_params, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST create' do
    it 'creates the element at the end of the step and logs an activity' do
      expect do
        post :create, params: { step_id: step.id }, format: :json
      end.to change { step.checklists.count }.by(1)
         .and change { activity_count(:task_step_checklist_added) }.by(1)
      expect(response).to have_http_status(:ok)
      created = step.checklists.order(:id).last
      expect(response.parsed_body['id']).to eq created.id
      expect(created.step_orderable_element.position).to be > step.step_orderable_elements.where.not(id: created.step_orderable_element.id).maximum(:position)
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      expect { post :create, params: { step_id: step.id }, format: :json }
        .not_to change { step.checklists.count }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 for an unknown step' do
      post :create, params: { step_id: 0 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT update' do
    it 'updates the element and logs an activity' do
      expect do
        put :update, params: base_params.merge(name: 'Updated name'), format: :json
      end.to change { activity_count(:task_step_checklist_edited) }.by(1)
      expect(response).to have_http_status(:ok)
      expect(element_checklist.reload.name).to eq 'Updated name'
      expect(element_checklist.last_modified_by).to eq user
      expect(response.parsed_body['name']).to eq 'Updated name'
    end

    it 'returns 404 for an element of another step' do
      put :update, params: { step_id: other_step.id, id: element_checklist.id }.merge(name: 'Updated name'), format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      put :update, params: base_params.merge(name: 'Updated name'), format: :json
      expect(response).to have_http_status(:forbidden)
      expect(element_checklist.reload.name).not_to eq 'Updated name'
    end

    it 'responds with 422 for a blank name' do
      put :update, params: base_params.merge(name: ''), format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(element_checklist.reload.name).not_to be_blank
    end
  end

  describe 'POST move' do
    it 'moves the element to the target step and logs an activity' do
      expect do
        post :move, params: base_params.merge(target_id: other_step.id), format: :json
      end.to change { activity_count(:task_step_checklist_moved) }.by(1)
      expect(response).to have_http_status(:ok)
      expect(element_checklist.reload.step).to eq other_step
      expect(element_checklist.step_orderable_element.step).to eq other_step
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      post :move, params: base_params.merge(target_id: other_step.id), format: :json
      expect(response).to have_http_status(:forbidden)
      expect(element_checklist.reload.step).to eq step
    end
  end

  describe 'POST duplicate' do
    it 'duplicates the element right after the original and logs an activity' do
      expect do
        post :duplicate, params: base_params, format: :json
      end.to change { step.checklists.count }.by(1)
         .and change { activity_count(:task_step_checklist_duplicated) }.by(1)
      expect(response).to have_http_status(:ok)
      copy = step.checklists.order(:id).last
      expect(response.parsed_body['id']).to eq copy.id
      expect(copy.step_orderable_element.position).to eq element_checklist.step_orderable_element.reload.position + 1
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      expect { post :duplicate, params: base_params, format: :json }
        .not_to change { step.checklists.count }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST archive' do
    it 'archives the element and logs an activity' do
      expect do
        post :archive, params: base_params, format: :json
      end.to change { activity_count(:task_step_checklist_archived) }.by(1)
      expect(response).to have_http_status(:ok)
      expect(element_checklist.reload).to be_archived
      expect(element_checklist.archived_by).to eq user
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      post :archive, params: base_params, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(element_checklist.reload).not_to be_archived
    end
  end

  describe 'POST restore' do
    before { element_checklist.archive!(user) }

    it 'restores the element and logs an activity' do
      expect do
        post :restore, params: base_params, format: :json
      end.to change { activity_count(:task_step_checklist_restored) }.by(1)
      expect(response).to have_http_status(:ok)
      expect(response.body).to be_blank
      expect(element_checklist.reload).not_to be_archived
      expect(element_checklist.restored_by).to eq user
    end

    it 'is forbidden for viewers' do
      downgrade_to_viewer
      post :restore, params: base_params, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(element_checklist.reload).to be_archived
    end
  end

  describe 'DELETE destroy' do
    it 'deletes an archived element and logs an activity' do
      element_checklist.archive!(user)
      expect do
        delete :destroy, params: base_params, format: :json
      end.to change { step.checklists.count }.by(-1)
         .and change { activity_count(:task_step_checklist_deleted) }.by(1)
      expect(response).to have_http_status(:ok)
    end

    it 'is forbidden while the element is still active' do
      expect { delete :destroy, params: base_params, format: :json }
        .not_to change { step.checklists.count }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST lock and unlock' do
    it 'is forbidden for task steps because content locking is repository-only' do
      post :lock, params: base_params, format: :json
      expect(response).to have_http_status(:forbidden)
      post :unlock, params: base_params, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(element_checklist.reload.locked).to be false
    end
  end
end
