# frozen_string_literal: true

require 'rails_helper'

describe ProjectFoldersController, type: :controller do
  login_user
  render_views

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, team: team, user: user, role: :admin }

  describe 'POST #move_to' do
    let!(:project_folder_1) do
      create :project_folder, name: 'test folder A', team: team
    end
    let!(:project_folder_2) do
      create :project_folder, name: 'test folder B', team: team
    end
    let!(:project_folder_3) do
      create :project_folder, name: 'test folder C', team: team, parent_folder: project_folder_2
    end
    let!(:project_1) do
      create :project, name: 'test project A', team: team, created_by: user
    end
    let!(:project_2) do
      create :project, name: 'test project B', team: team, project_folder: project_folder_2, created_by: user
    end
    let!(:project_3) do
      create :project, name: 'test project C', team: team, project_folder: project_folder_3, created_by: user
    end

    context 'in JSON format' do
      let(:action) { post :move_to, params: params, format: :json }
      let(:params) do
        {
          id: project_folder_1.id,
          movables: [
            { id: project_1.id, type: :project },
            { id: project_folder_2.id, type: :project_folder }
          ]
        }
      end

      it 'returns success response' do
        post :move_to, params: params, format: :json
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        expect(project_1.reload.project_folder).to(be_eql(project_folder_1))
        expect(project_folder_2.reload.parent_folder).to(be_eql(project_folder_1))
        expect(project_folder_3.reload.parent_folders).to(include(project_folder_1))
        expect(project_3.reload.project_folder.parent_folder.parent_folder).to(be_eql(project_folder_1))
      end
    end
  end
end
