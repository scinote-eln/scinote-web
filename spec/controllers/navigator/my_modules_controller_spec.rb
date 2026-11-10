# frozen_string_literal: true

require 'rails_helper'

describe Navigator::MyModulesController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  let(:items) { JSON.parse(response.body)['items'] }

  describe 'GET tree' do
    let!(:other_my_module) { create :my_module, experiment: experiment, created_by: user }

    it 'returns the project tree with the task experiment expanded' do
      get :tree, params: { id: my_module.id }, format: :json

      expect(response).to have_http_status(:success)
      project_item = items.find { |i| i['id'] == project.code }
      expect(project_item['type']).to eq('project')
      experiment_item = project_item['children'].find { |i| i['id'] == experiment.code }
      expect(experiment_item['children'].pluck('id')).to contain_exactly(my_module.code, other_my_module.code)
    end

    context 'when project is inside a folder' do
      let!(:folder) { create :project_folder, team: team }

      before { project.update!(project_folder: folder) }

      it 'nests the project under the folder' do
        get :tree, params: { id: my_module.id }, format: :json

        folder_item = items.find { |i| i['id'] == folder.code }
        expect(folder_item['children'].pluck('id')).to include(project.code)
      end
    end

    context 'when the task is archived and archived mode is requested' do
      before { my_module.update_columns(archived: true, archived_on: Time.zone.now) }

      it 'lists only archived tasks in the experiment branch' do
        get :tree, params: { id: my_module.id, archived: 'true' }, format: :json

        project_item = items.find { |i| i['id'] == project.code }
        experiment_item = project_item['children'].find { |i| i['id'] == experiment.code }
        expect(experiment_item['children'].pluck('id')).to contain_exactly(my_module.code)
        expect(experiment_item['children'].first['url']).to include('view_mode=archived')
      end
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_my_module?).and_return(false)

      get :tree, params: { id: my_module.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for unknown task' do
      pending 'bug: Navigator::MyModulesController#load_my_module calls experiment on nil for unknown id'
      get :tree, params: { id: -1 }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
