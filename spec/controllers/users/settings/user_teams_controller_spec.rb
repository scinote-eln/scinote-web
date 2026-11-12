# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::UserTeamsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:normal_role) { create :normal_user_role }
  let!(:viewer_role) { create :viewer_role }
  let!(:other_user) { create :user }
  let!(:other_assignment) { create_user_assignment(team, normal_role, other_user, user) }
  let(:own_assignment) { team.user_assignments.find_by(user: user) }
  let(:job) { instance_double(ActiveJob::Base, job_id: 'job-123') }

  before do
    allow(UserAssignments::RemoveTeamUserAssignmentsJob).to receive(:perform_later).and_return(job)
  end

  describe 'PUT update' do
    it 'changes the role and logs an activity' do
      expect do
        put :update, params: { id: other_assignment.id, user_assignment: { user_role_id: viewer_role.id } },
                     format: :json
      end.to change { Activity.where(type_of: :change_users_role_on_team).count }.by(1)
      expect(response).to have_http_status(:success)
      expect(other_assignment.reload.user_role).to eq viewer_role
    end

    it 'returns errors for an invalid role' do
      put :update, params: { id: other_assignment.id, user_assignment: { user_role_id: nil } }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'is forbidden without user management permission' do
      own_assignment.update!(user_role: viewer_role)
      put :update, params: { id: other_assignment.id, user_assignment: { user_role_id: viewer_role.id } },
                   format: :json
      expect(response).to have_http_status(:forbidden)
      expect(other_assignment.reload.user_role).to eq normal_role
    end
  end

  describe 'GET leave_html / destroy_html' do
    it 'returns the leave modal for the own assignment' do
      get :leave_html, params: { id: own_assignment.id, leave: true }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to include('html', 'heading')
    end

    it 'forbids leave modal for another user assignment' do
      get :leave_html, params: { id: other_assignment.id, leave: true }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns the destroy modal for a manager' do
      get :destroy_html, params: { id: other_assignment.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('html')
    end

    it 'forbids destroy modal for a non manager' do
      own_assignment.update!(user_role: viewer_role)
      get :destroy_html, params: { id: other_assignment.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE destroy' do
    it 'removes another user from the team' do
      other_user.update!(current_team_id: team.id)
      expect do
        delete :destroy, params: { id: other_assignment.id }, format: :json
      end.to change { Activity.where(type_of: :remove_user_from_team).count }.by(1)
      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body['job_id']).to eq 'job-123'
      expect(body['redirect_url']).to be_nil
      expect(UserAssignments::RemoveTeamUserAssignmentsJob).to have_received(:perform_later)
        .with(other_assignment, assigner_id: user.id)
    end

    it 'lets a user leave a team and redirects to the teams list' do
      other_assignment.update!(user_role: owner_role)
      expect do
        delete :destroy, params: { id: own_assignment.id, leave: true }, format: :json
      end.to change { Activity.where(type_of: :user_leave_team).count }.by(1)
      expect(JSON.parse(response.body)['redirect_url']).to eq teams_path
    end

    it 'refuses to remove the last user manager' do
      expect do
        delete :destroy, params: { id: own_assignment.id, leave: true }, format: :json
      end.not_to(change { Activity.count })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(UserAssignments::RemoveTeamUserAssignmentsJob).not_to have_received(:perform_later)
    end

    it 'returns unprocessable entity when removal fails' do
      allow(Activities::CreateActivityService).to receive(:call).and_raise(StandardError, 'boom')
      delete :destroy, params: { id: other_assignment.id }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'is forbidden to remove a user without permission' do
      own_assignment.update!(user_role: viewer_role)
      delete :destroy, params: { id: other_assignment.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden to make another user leave' do
      delete :destroy, params: { id: other_assignment.id, leave: true }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
