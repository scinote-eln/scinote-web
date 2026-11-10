# frozen_string_literal: true

require 'rails_helper'

describe StepOrderableElementsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { step: true }

  let!(:element_a) { create :step_orderable_element, step: step, position: 0 }
  let!(:element_b) { create :step_orderable_element, step: step, position: 1 }
  let(:positions) { { element_a.id.to_s => '1', element_b.id.to_s => '0' } }

  def downgrade_to_viewer
    UserAssignment.where(user: user, assignable: [my_module, experiment, project])
                  .update_all(user_role_id: viewer_role.id)
  end

  describe 'POST #reorder' do
    it 'stores the new positions and echoes them back' do
      post :reorder, params: { step_id: step.id, step_orderable_element_positions: positions }, format: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq positions
      expect(element_a.reload.position).to eq 1
      expect(element_b.reload.position).to eq 0
    end

    it 'logs a task_step_content_rearranged activity for a task step' do
      allow(Activities::CreateActivityService).to receive(:call)
      post :reorder, params: { step_id: step.id, step_orderable_element_positions: positions }, format: :json
      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: :task_step_content_rearranged,
                       owner: user,
                       subject: step.protocol,
                       project: project,
                       message_items: hash_including(step: step.id, my_module: my_module.id))
      )
    end

    it 'touches the step' do
      step.update_column(:updated_at, 1.day.ago)
      post :reorder, params: { step_id: step.id, step_orderable_element_positions: positions }, format: :json
      expect(step.reload.updated_at).to be > 1.hour.ago
    end

    it 'does not log an activity when positions did not change' do
      allow(Activities::CreateActivityService).to receive(:call)
      pending 'bug: positions arrive as strings so the unchanged check (!=) always reports a change'
      post :reorder, params: { step_id: step.id,
                               step_orderable_element_positions: { element_a.id.to_s => '0', element_b.id.to_s => '1' } },
                     format: :json
      expect(Activities::CreateActivityService).not_to have_received(:call)
    end

    it 'returns 404 for an element that is not part of the step' do
      pending 'bug: an element outside the step raises ActiveRecord::RecordNotFound instead of rendering 404'
      other = create :step_orderable_element
      post :reorder, params: { step_id: step.id, step_orderable_element_positions: { other.id.to_s => '0' } },
                     format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an unknown step' do
      post :reorder, params: { step_id: 0, step_orderable_element_positions: positions }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for viewers and keeps positions' do
      downgrade_to_viewer
      post :reorder, params: { step_id: step.id, step_orderable_element_positions: positions }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(element_a.reload.position).to eq 0
    end

    context 'when the step belongs to a repository protocol' do
      let(:team_protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
      let(:repo_step) { create :step, protocol: team_protocol }
      let!(:repo_element) { create :step_orderable_element, step: repo_step, position: 0 }

      it 'logs a protocol_step_content_rearranged activity' do
        allow(Activities::CreateActivityService).to receive(:call)
        post :reorder, params: { step_id: repo_step.id, step_orderable_element_positions: { repo_element.id.to_s => '4' } },
                       format: :json
        expect(response).to have_http_status(:ok)
        expect(repo_element.reload.position).to eq 4
        expect(Activities::CreateActivityService).to have_received(:call).with(
          hash_including(activity_type: :protocol_step_content_rearranged,
                         subject: team_protocol,
                         team: team,
                         message_items: hash_including(step: repo_step.id, protocol: team_protocol.id))
        )
      end

      it 'is forbidden for a user who only has the viewer role on the protocol' do
        viewer = create :user
        viewer.confirm
        create :user_assignment, assignable: team, user: viewer, user_role: viewer_role, assigned_by: user
        create_user_assignment(team_protocol, viewer_role, viewer, user)
        sign_out user
        sign_in viewer
        allow(Activities::CreateActivityService).to receive(:call)
        post :reorder, params: { step_id: repo_step.id, step_orderable_element_positions: { repo_element.id.to_s => '4' } },
                       format: :json
        expect(response).to have_http_status(:forbidden)
        expect(repo_element.reload.position).to eq 0
        expect(Activities::CreateActivityService).not_to have_received(:call)
      end
    end
  end
end
