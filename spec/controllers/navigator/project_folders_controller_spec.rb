# frozen_string_literal: true

require 'rails_helper'

describe Navigator::ProjectFoldersController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  let(:items) { JSON.parse(response.body)['items'] }
  let!(:parent_folder) { create :project_folder, team: team }
  let!(:folder) { create :project_folder, team: team, parent_folder: parent_folder }
  let!(:sub_folder) { create :project_folder, team: team, parent_folder: folder }

  before { project.update!(project_folder: folder) }

  describe 'GET show' do
    it 'returns projects and sub folders inside the folder' do
      get :show, params: { id: folder.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(items.pluck('id')).to contain_exactly(project.code, sub_folder.code)
      sub_folder_item = items.find { |i| i['id'] == sub_folder.code }
      expect(sub_folder_item).to include('type' => 'folder',
                                         'children_url' => "/navigator/project_folders/#{sub_folder.id}")
    end

    it 'marks parent folder as having children' do
      get :show, params: { id: parent_folder.id }, format: :json

      folder_item = items.find { |i| i['id'] == folder.code }
      expect(folder_item['has_children']).to be(true)
    end
  end

  describe 'GET tree' do
    it 'returns the root tree with the folder branch expanded' do
      get :tree, params: { id: folder.id }, format: :json

      expect(response).to have_http_status(:success)
      parent_item = items.find { |i| i['id'] == parent_folder.code }
      folder_item = parent_item['children'].find { |i| i['id'] == folder.code }
      expect(folder_item['children'].pluck('id')).to contain_exactly(project.code, sub_folder.code)
    end
  end
end
