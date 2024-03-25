# frozen_string_literal: true

require 'rails_helper'

describe ProjectFoldersController, type: :controller do
  login_user
  # render_views

  include_context 'reference_project_structure'

  let(:project_folder) { create :project_folder, team: team }


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
          destination_folder_id: project_folder_1.id,
          movables: [
            { id: project_1.id, type: :projects },
            { id: project_folder_2.id, type: :project_folders }
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

      it 'adds 1 move_porject and 1 move_project_folder activity in DB' do
        expect { action }.to(change { Activity.where(type_of: :move_project).count }.by(1)
                               .and(change { Activity.where(type_of: :move_project_folder).count }.by(1)))
      end
    end
  end

  describe 'POST create' do
    let(:action) { post :create, params: { project_folder: { name: 'My Proejct Folder' } }, format: :json }

    it 'calls create activity for creating project folder' do
      expect(Activities::CreateActivityService)
        .to(receive(:call).with(hash_including(activity_type: :create_project_folder)))

      action
    end

    it 'adds activity in DB' do
      expect { action }.to(change { Activity.count }.by(1))
    end

    it 'adds ProjectFolder in DB' do
      expect { action }.to(change { ProjectFolder.count }.by(1))
    end
  end

  describe 'PATCH update' do
    let(:action) do
      patch :update,
            params: { project_folder: { name: 'new name' }, id: project_folder.id }, format: :json
    end

    it 'calls create activity for creating project folder' do
      expect(Activities::CreateActivityService)
        .to(receive(:call).with(hash_including(activity_type: :rename_project_folder)))

      action
    end

    it 'adds activity in DB' do
      expect { action }.to(change { Activity.count }.by(1))
    end
  end
end
