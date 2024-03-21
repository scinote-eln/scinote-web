# frozen_string_literal: true

require 'rails_helper'

describe ProjectsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    projects: 3,
    skip_my_module: true,
    skip_experiment: true,
    team_role: :owner
  }

  describe '#index' do
    let(:params) { { team: team.id, sort: 'atoz' } }

    it 'returns success response' do
      get :index, params: params
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST create' do
    context 'in JSON format' do
      let(:params) do
        { project: { name: 'test project A1', team_id: team.id,
                     visibility: 'visible', archived: false } }
      end
      let(:action) { post :create, params: params, format: :json }

      it 'returns success response, then unprocessable_entity on second run' do
        get :create, params: params, format: :json
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        get :create, params: params, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq 'application/json'
      end

      it 'calls create activity for creating project' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :create_project)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'PUT update' do
    context 'in HTML format' do
      let(:action) { put :update, params: params }
      let(:params) do
        { id: projects.first.id,
          project: { name: projects.first.name,
                     visibility: projects.first.visibility,
                     default_public_user_role_id: projects.first.default_public_user_role.id } }
      end

      it 'returns redirect response' do
        action
        expect(response).to have_http_status(:redirect)
        expect(response.media_type).to eq 'text/html'
      end

      it 'calls create activity service (project_grant_access_to_all_team_members)' do
        params[:project][:visibility] = 'visible'
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :project_grant_access_to_all_team_members))
        action
      end

      it 'adds activity in DB' do
        params[:project][:archived] = true
        expect { action }
          .to(change { Activity.count })
      end
    end
  end
end
