# frozen_string_literal: true

require 'rails_helper'

describe Navigator::ExperimentsController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  let(:items) { JSON.parse(response.body)['items'] }
  let!(:archived_my_module) do
    create :my_module, :archived, experiment: experiment, created_by: user
  end

  describe 'GET show' do
    it 'returns active tasks of the experiment' do
      get :show, params: { id: experiment.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(items.pluck('id')).to contain_exactly(my_module.code)
      expect(items.first).to include(
        'name' => my_module.name,
        'type' => 'my_module',
        'archived' => false,
        'has_children' => false
      )
      expect(items.first['url']).to include("/modules/#{my_module.id}/protocols", 'view_mode=active')
    end

    it 'returns archived tasks in archived mode' do
      get :show, params: { id: experiment.id, archived: 'true' }, format: :json

      expect(items.pluck('id')).to contain_exactly(archived_my_module.code)
      expect(items.first['url']).to include('view_mode=archived')
    end

    context 'when experiment is archived' do
      before { experiment.update_columns(archived: true, archived_on: Time.zone.now) }

      it 'returns all tasks regardless of their archived state' do
        get :show, params: { id: experiment.id, archived: 'true' }, format: :json

        expect(items.pluck('id')).to contain_exactly(my_module.code, archived_my_module.code)
        expect(items.pluck('archived')).to all(be(true))
      end
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_experiment?).and_return(false)

      get :show, params: { id: experiment.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET tree' do
    it 'returns project tree with experiment and its tasks nested' do
      get :tree, params: { id: experiment.id }, format: :json

      expect(response).to have_http_status(:success)
      project_item = items.find { |i| i['id'] == project.code }
      experiment_item = project_item['children'].find { |i| i['id'] == experiment.code }
      expect(experiment_item['children'].pluck('id')).to contain_exactly(my_module.code)
    end

    context 'when project is in a folder' do
      let!(:folder) { create :project_folder, team: team }

      before { project.update!(project_folder: folder) }

      it 'wraps the tree into the folder branch' do
        get :tree, params: { id: experiment.id }, format: :json

        folder_item = items.find { |i| i['id'] == folder.code }
        project_item = folder_item['children'].find { |i| i['id'] == project.code }
        expect(project_item['children'].pluck('id')).to include(experiment.code)
      end
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_experiment?).and_return(false)

      get :tree, params: { id: experiment.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
