# frozen_string_literal: true

require 'rails_helper'

describe Navigator::ProjectsController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  let(:json) { JSON.parse(response.body) }
  let(:items) { json['items'] }

  describe 'GET index' do
    let!(:folder) { create :project_folder, team: team, name: 'Root folder' }
    let!(:archived_project) { create :project, :archived, team: team, created_by: user }

    it 'returns active root projects and folders with serialized attributes' do
      get :index, format: :json

      expect(response).to have_http_status(:success)
      project_item = items.find { |i| i['id'] == project.code }
      expect(project_item).to include(
        'name' => project.name,
        'type' => 'project',
        'archived' => false,
        'has_children' => true,
        'disabled' => false,
        'children_url' => "/navigator/projects/#{project.id}"
      )
      expect(project_item['url']).to eq("/projects/#{project.id}/experiments?view_mode=active")

      folder_item = items.find { |i| i['id'] == folder.code }
      expect(folder_item).to include('name' => 'Root folder', 'type' => 'folder', 'archived' => false,
                                     'has_children' => false)
      expect(folder_item['url']).to include('view_mode=active')
      expect(items.pluck('id')).not_to include(archived_project.code)
    end

    it 'returns archived projects when archived param is true' do
      get :index, params: { archived: 'true' }, format: :json

      ids = items.pluck('id')
      expect(ids).to include(archived_project.code)
      expect(ids).not_to include(project.code, folder.code)
      archived_item = items.find { |i| i['id'] == archived_project.code }
      expect(archived_item['url']).to include('view_mode=archived')
      expect(archived_item['archived']).to be(true)
    end

    context 'when user is not a team manager' do
      include_context 'reference_project_structure', team_role: :normal_user

      let!(:other_users_project) { create :project, team: team, created_by: create(:user) }

      it 'lists only projects readable by the user' do
        get :index, format: :json

        ids = items.pluck('id')
        expect(ids).to include(project.code)
        expect(ids).not_to include(other_users_project.code)
      end
    end
  end

  describe 'GET show' do
    let!(:archived_experiment) { create :experiment, :archived, project: project, created_by: user }

    it 'returns active experiments of the project' do
      get :show, params: { id: project.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(items.pluck('id')).to contain_exactly(experiment.code)
      expect(items.first).to include(
        'name' => experiment.name,
        'type' => 'experiment',
        'archived' => false,
        'has_children' => true,
        'children_url' => "/navigator/experiments/#{experiment.id}"
      )
    end

    it 'returns archived experiments in archived mode' do
      get :show, params: { id: project.id, archived: 'true' }, format: :json

      expect(items.pluck('id')).to contain_exactly(archived_experiment.code)
      expect(items.first['archived']).to be(true)
      expect(items.first['url']).to include('view_mode=archived')
    end

    context 'when project is archived' do
      before { project.update_columns(archived: true, archived_on: Time.zone.now) }

      it 'returns all experiments with tasks as children in archived mode' do
        get :show, params: { id: project.id, archived: 'true' }, format: :json

        expect(items.pluck('id')).to include(experiment.code, archived_experiment.code)
        expect(items.find { |i| i['id'] == experiment.code }['has_children']).to be(true)
      end
    end

    it 'returns not found for a project outside of the current team' do
      get :show, params: { id: create(:project).id }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_project?).and_return(false)

      get :show, params: { id: project.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET tree' do
    it 'returns root level branch when project has no folder' do
      get :tree, params: { id: project.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(items.pluck('id')).to include(project.code)
    end

    context 'when project is inside nested folders' do
      let!(:parent_folder) { create :project_folder, team: team }
      let!(:child_folder) { create :project_folder, team: team, parent_folder: parent_folder }

      before { project.update!(project_folder: child_folder) }

      it 'nests the project branch under its folders' do
        get :tree, params: { id: project.id }, format: :json

        parent_item = items.find { |i| i['id'] == parent_folder.code }
        expect(parent_item).to be_present
        child_item = parent_item['children'].find { |i| i['id'] == child_folder.code }
        expect(child_item).to be_present
        expect(child_item['children'].pluck('id')).to include(project.code)
      end

      it 'adds folder to the tree when its archived state does not match the mode' do
        get :tree, params: { id: project.id, archived: 'true' }, format: :json

        parent_item = items.find { |i| i['id'] == parent_folder.code }
        expect(parent_item['children'].pluck('id')).to include(child_folder.code)
      end
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_project?).and_return(false)

      get :tree, params: { id: project.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
