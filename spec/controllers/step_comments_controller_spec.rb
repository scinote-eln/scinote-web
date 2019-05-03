# frozen_string_literal: true

require 'rails_helper'

describe StepCommentsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:project) { create :project, team: team, created_by: user }
  let!(:user_project) do
    create :user_project, :normal_user, user: user, project: project
  end
  let(:experiment) { create :experiment, project: project }
  let(:my_module) { create :my_module, experiment: experiment }
  let(:protocol) do
    create :protocol, my_module: my_module, team: team, added_by: user
  end
  let(:step) { create :step, protocol: protocol, user: user }
  let(:step_comment) { create :step_comment, user: user, step: step }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { step_id: step.id, comment: { message: 'comment created' } }
    end

    it 'calls create activity for adding comment to step' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :add_comment_to_step)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      { step_id: step.id,
        id: step_comment.id,
        comment: { message: 'comment updated' } }
    end

    it 'calls create activity for editing comment on step' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :edit_step_comment)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params, format: :json }
    let(:params) do
      { step_id: step.id, id: step_comment.id }
    end

    it 'calls create activity for deleting comment on step' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_step_comment)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
