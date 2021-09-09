# frozen_string_literal: true

require 'rails_helper'

describe ResultsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let!(:team) { create :team, :with_members }
  let(:project) do
    create :project, team: team
  end
  let(:owner_role) { create :owner_role }

  let(:experiment) { create :experiment, project: project }
  let(:task) { create :my_module, name: 'test task', experiment: experiment }
  let(:result) do
    create :result, :archived, name: 'test result', my_module: task, user: user
  end
  let!(:result_text) do
    create :result_text, text: 'test text result', result: result
  end

  before do
    create_user_assignment(task, owner_role, user)
  end

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params }
    let(:params) do
      { id: result.id }
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
  end
end
