# frozen_string_literal: true

require 'rails_helper'

describe ProjectActivitiesController, type: :controller do
  login_user
  render_views

  include_context 'reference_project_structure', { team_role: :owner }

  let(:json) { JSON.parse(response.body) }

  describe 'GET index' do
    it 'renders the placeholder when the project has no activities' do
      get :index, params: { project_id: project.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['html']).to include(I18n.t('projects.index.no_activities'))
    end

    it 'renders the latest activities with the task name' do
      create :activity, :old, project: project, experiment: experiment, my_module: my_module,
                              owner: user, team: team, message: 'Did something notable'

      get :index, params: { project_id: project.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['html']).to include('Did something notable', my_module.name)
    end

    it 'returns 404 for an unknown project' do
      get :index, params: { project_id: 0 }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 without read permission' do
      without_partial_double_verification do
        allow(controller).to receive(:can_read_project?).and_return(false)
      end

      get :index, params: { project_id: project.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
