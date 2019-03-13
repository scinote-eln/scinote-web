# frozen_string_literal: true

require 'rails_helper'

describe ResultsController, type: :controller do
  login_user

  let(:user) { User.first }
  let!(:team) { create :team, :with_members }
  let!(:user_project) { create :user_project, :owner, user: user }
  let(:project) do
    create :project, team: team, user_projects: [user_project]
  end
  let(:experiment) { create :experiment, project: project }
  let(:task) { create :my_module, name: 'test task', experiment: experiment }
  let(:result) do
    create :result, name: 'test result', my_module: task, user: user
  end
  let!(:result_text) do
    create :result_text, text: 'test text result', result: result
  end

  describe '#destroy' do
    let(:params) do
      { id: result.id }
    end

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :destroy_result))

      delete :destroy, params: params
    end
  end
end
