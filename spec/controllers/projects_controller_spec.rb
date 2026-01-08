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
    before(:all) do
      MyModuleStatusFlow.ensure_default
    end

    let(:params) { { team: team.id, sort: 'atoz' } }

    it 'returns json success response' do
      get :index, params: params, format: :json 
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(team.projects.active.count)
    end

    it 'returns html success response' do
      get :index, params: params, format: :html 
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET show' do
    let(:action) { get :show, params: { id: projects.first.id }, format: :json }

    it 'correct JSON format' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).to eq(projects.first.id.to_s)
    end
  end

  describe 'GET inventory_assigning_project_filter' do
    let(:action) { get :inventory_assigning_project_filter }

    it 'correct JSON format' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'text/plain'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_empty
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
                     supervised_by_id: user.id,
                     start_date: Date.today,
                     due_date: Date.today,
                     status: 'done' } }
      end

      it 'returns redirect response' do
        action
        expect(response).to have_http_status(:redirect)
        expect(response.media_type).to eq 'text/html'
      end

      it 'adds activity in DB' do
        params[:project][:archived] = true
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'incorrect name format update' do
      let(:action) { put :update, params: params, format: :json }
      let(:params) do
        { id: projects.first.id,
          project: { name: '' } }
      end

      it 'returns redirect response' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST favorite' do
    let(:action) { post :favorite, params: { id: project.id } }

    it 'creates a favorite' do
      expect(user.favorites.exists?(item: project )).to eq(false)
      action
      expect(user.favorites.exists?(item: project )).to eq(true)
    end
  end

  describe 'POST unfavorite' do
    let(:action) { post :unfavorite, params: { id: project.id } }

    it 'removes a favorite' do
      Favorite.create!(user: user, item: project, team: project.team)
      action
      expect(user.favorites.exists?(item: project )).to eq(false)
    end
  end

  describe 'GET projects_to_move' do
    let(:action) { get :projects_to_move, params: { query: ''}, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(team.projects.active.count)
    end
  end

  describe 'GET users_filter' do
    let(:action) { get :users_filter, params: { query: ''}, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)['data']).to be_an(Array)
    end
  end

  describe 'GET head_of_project_users_list' do
    let(:action) { get :head_of_project_users_list, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)['data']).to be_an(Array)
    end
  end

  describe 'GET assigned_users_list' do
    let(:action) { get :assigned_users_list, params: { id: projects.first.id}, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)['data']).to be_an(Array)
    end
  end

  describe 'GET #user_roles' do
    it 'returns a http success response' do
      get :user_roles, params: { id: projects.first.id }, format: :json
      expect(response).to have_http_status :success
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET actions_toolbar' do
    let(:action) { get :actions_toolbar, params: { items: [{ id: projects.first.id }].to_json }, format: :json }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)['actions']).to be_an(Array)
    end
  end

  describe 'POST archive_group' do
    let(:action) { post :archive_group, params: { project_ids: project_list } }

    context 'when valid projects' do
      let(:project_list) { projects.pluck(:id) }
      it 'archive projects' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :archive_project)).exactly(3).times

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when not valid projects' do
      let(:project_list) { [-1] }
      it 'archive projects' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq 'application/json'
      end
    end
  end

   describe 'POST restore_group' do
    let(:action) { post :restore_group, params: { project_ids: project_list } }
    let(:archived_project) do
        create :project,
               archived: true,
               archived_by: user,
               archived_on: Time.zone.now,
               team: team,
               created_by: user
      end

    context 'when valid projects' do
      let(:project_list) { [archived_project.id] }
      it 'restore projects' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :restore_project))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when not valid projects' do
      let(:project_list) { [-1] }
      it 'restore projects' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq 'application/json'
      end
    end
  end
end
