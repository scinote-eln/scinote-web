# frozen_string_literal: true

require 'rails_helper'

describe ProjectsController, type: :controller do
  login_user
  render_views

  PROJECTS_CNT = 26
  time = Time.new(2015, 8, 1, 14, 35, 0)
  let!(:user) { User.first }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, team: team, user: user }
  before do
    @projects_overview = ProjectsOverviewService.new(team, user, params)
  end

  let!(:project_1) do
    create :project, name: 'test project D', visibility: 1, team: team,
                     archived: false, created_at: time.advance(hours: 2),
                     created_by: user
  end
  let!(:project_2) do
    create :project, name: 'test project B', visibility: 1, team: team,
                     archived: true, created_at: time, created_by: user
  end
  let!(:project_3) do
    create :project, name: 'test project C', visibility: 1, team: team,
                     archived: false, created_at: time.advance(hours: 3),
                     created_by: user
  end
  let!(:project_4) do
    create :project, name: 'test project A', visibility: 1, team: team,
                     archived: true, created_at: time.advance(hours: 1),
                     created_by: user
  end
  let!(:project_5) do
    create :project, name: 'test project E', visibility: 1, team: team,
                     archived: true, created_at: time.advance(hours: 5),
                     created_by: user
  end
  let!(:project_6) do
    create :project, name: 'test project F', visibility: 0, team: team,
                     archived: false, created_at: time.advance(hours: 4),
                     created_by: user
  end
  (7..PROJECTS_CNT).each do |i|
    let!("project_#{i}") do
      create :project, name: "test project #{(64 + i).chr}",
                       visibility: 1,
                       team: team, archived: i % 2,
                       created_at: time.advance(hours: 6, minutes: i),
                       created_by: user
    end
  end

  # rubocop:disable Security/Eval
  # rubocop:disable Style/EvalWithLocation
  (1..PROJECTS_CNT).each do |i|
    let!("user_projects_#{i}") do
      create :user_project, :owner, project: eval("project_#{i}"), user: user
    end
  end
  # rubocop:enable Security/Eval
  # rubocop:enable Style/EvalWithLocation

  describe '#index' do
    context 'in JSON format' do
      let(:params) { { team: team.id, sort: 'atoz' } }

      it 'returns success response' do
        get :index, params: params, format: :json
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end
    end
  end

  describe '#index_dt' do
    context 'in JSON format' do
      let(:params) do
        { start: 1, length: 2, order: { '0': { dir: 'ASC', column: '2' } } }
      end

      it 'returns success response' do
        get :index_dt, params: params, format: :json
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end
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

  describe '#edit' do
    context 'in JSON format' do
      let(:params) { { id: project_1.id } }

      it 'returns success response' do
        get :edit, params: params, format: :json
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end
    end
  end

  describe 'PUT update' do
    context 'in HTML format' do
      let(:action) { put :update, params: params }
      let(:params) do
        { id: project_1.id,
          project: { name: project_1.name, team_id: project_1.team.id,
                     visibility: project_1.visibility } }
      end

      it 'returns redirect response' do
        action
        expect(response).to have_http_status(:redirect)
        expect(response.media_type).to eq 'text/html'
      end

      it 'calls create activity service (change_project_visibility)' do
        params[:project][:visibility] = 'hidden'
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :change_project_visibility))
        action
      end

      it 'calls create activity service (rename_project)' do
        params[:project][:name] = 'test project changed'
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :rename_project))
        action
      end

      it 'calls create activity service (restore_project)' do
        project_1.update(archived: true)
        params[:project][:archived] = false
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :restore_project))
        action
      end

      it 'calls create activity service (archive_project)' do
        params[:project][:archived] = true
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :archive_project))
        action
      end

      it 'adds activity in DB' do
        params[:project][:archived] = true
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe '#show' do
    context 'in HTML format' do
      let(:params) do
        { id: project_1.id, sort: 'old',
          project: { name: 'test project A1', team_id: team.id,
                     visibility: 'visible' } }
      end

      it 'returns success response' do
        get :show, params: params
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'text/html'
      end
    end
  end

  describe '#notifications' do
    context 'in JSON format' do
      let(:params) do
        { id: project_1.id,
          project: { name: 'test project A1', team_id: team.id,
                     visibility: 'visible' } }
      end

      it 'returns success response' do
        get :notifications, format: :json, params: params
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end
    end
  end

  describe '#experiment_archive' do
    context 'in HTML format' do
      let(:params) do
        { id: project_1.id,
          project: { name: 'test project A1', team_id: team.id,
                     visibility: 'visible' } }
      end

      it 'returns success response' do
        get :experiment_archive, params: params
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'text/html'
      end
    end
  end
end
