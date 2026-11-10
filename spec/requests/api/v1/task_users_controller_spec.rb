# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::TaskUsersController', type: :request do
  let(:user) { create :user }
  let(:other_user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) || create(:owner_role) }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:task) { create :my_module, experiment: experiment, created_by: user }
  let(:headers) { { 'Authorization': "Bearer #{generate_token(user.id)}" } }

  let(:base_path) do
    api_v1_team_project_experiment_task_users_path(team_id: team.id, project_id: project.id,
                                                   experiment_id: experiment.id, task_id: task.id)
  end

  before do
    create_user_assignment(task, owner_role, user)
    create_user_assignment(task, owner_role, other_user)
  end

  describe 'GET #index' do
    it 'returns the users assigned to the task' do
      get base_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json[:data].map { |u| u['id'].to_i }).to contain_exactly(user.id, other_user.id)
      expect(json[:data].first['type']).to eq('users')
    end

    it 'paginates the results' do
      get base_path, params: { page: { number: 1, size: 1 } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json[:data].size).to eq(1)
    end

    it 'returns 404 for an unknown task' do
      get api_v1_team_project_experiment_task_users_path(team_id: team.id, project_id: project.id,
                                                         experiment_id: experiment.id, task_id: -1),
          headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 when the user has no access to the project' do
      outsider = create :user
      get base_path, headers: { 'Authorization': "Bearer #{generate_token(outsider.id)}" }

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 401 without a token' do
      get base_path

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET #show' do
    it 'returns a single assigned user' do
      get "#{base_path}/#{other_user.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json[:data]['id'].to_i).to eq(other_user.id)
      expect(json[:data]['attributes']['full_name']).to eq(other_user.full_name)
    end

    it 'returns 404 for a user not assigned to the task' do
      stranger = create :user
      get "#{base_path}/#{stranger.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
