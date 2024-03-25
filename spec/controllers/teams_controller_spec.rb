# frozen_string_literal: true

require 'rails_helper'

describe TeamsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }

  describe 'POST export_projects' do
    let!(:first_project) { create :project, team: team, created_by: user }
    let!(:second_project) { create :project, team: team, created_by: user }
    let(:params) do
      {
        id: team.id,
        project_ids: [first_project.id, second_project.id]
      }
    end
    let(:action) { post :export_projects, params: params, format: :json }

    it 'calls create activity for inviting user' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :export_projects)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  # Temporary disabled due to webpack problems
  end if false
end
