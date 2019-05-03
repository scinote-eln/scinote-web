# frozen_string_literal: true

require 'rails_helper'

describe UserProjectsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:user_two) { create :user }
  let(:target_user) { create :user }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, team: team, user: user }
  let(:user_project) { create :user_project, :owner, user: user }
  let(:target_user_project) do
    create :user_project, :normal_user, user: target_user
  end
  let(:project) do
    create :project, team: team, user_projects: [user_project,
                                                 target_user_project]
  end

  describe 'POST create' do
    context 'in JSON format' do
      let(:action) { post :create, params: params, format: :json }
      let(:params) do
        { project_id: project.id,
          user_project: { user_id: user_two.id,
                          project_id: project.id,
                          role: :owner } }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :assign_user_to_project))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'PUT update' do
    context 'in JSON format' do
      let(:action) { put :update, params: params, format: :json }
      let(:params) do
        { project_id: project.id,
          id: target_user_project.id,
          user_project: { user_id: target_user.id,
                          project_id: project.id,
                          role: :viewer } }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :change_user_role_on_project))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'DELETE destroy' do
    context 'in JSON format' do
      let(:action) { delete :destroy, params: params, format: :json }
      let(:params) do
        { project_id: project.id,
          id: target_user_project.id }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :unassign_user_from_project))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end
end
