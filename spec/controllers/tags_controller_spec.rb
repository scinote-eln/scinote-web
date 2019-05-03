# frozen_string_literal: true

require 'rails_helper'

describe TagsController, type: :controller do
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

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:tag) { create :tag, project: project }
    let(:params) do
      {
        my_module_id: my_module.id,
        project_id: project.id,
        tag: { project_id: project.id,
               name: 'name',
               color: '#123456' }
      }
    end

    it 'calls create activity for adding task tag' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :add_task_tag)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
