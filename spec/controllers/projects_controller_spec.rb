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

  (1..PROJECTS_CNT).each do |i|
    let!("user_projects_#{i}") do
      create :user_project, project: eval("project_#{i}"), user: user
    end
  end

  describe '#index' do
    context 'in JSON format' do
      let(:params) { { team: team.id, sort: 'atoz' } }

      it 'returns success response' do
        get :index, params: params, format: :json
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq 'application/json'
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
        expect(response.content_type).to eq 'application/json'
      end
    end
  end

  describe '#archive' do
    context 'in JSON format' do
      let(:params) { { team: team.id, sort: 'atoz' } }

      it 'returns success response' do
        get :archive, params: params, format: :json
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq 'application/json'
      end
    end
  end

  describe '#create' do
    context 'in JSON format' do
      let(:params) do
        { project: { name: 'test project A1', team_id: team.id,
                     visibility: 'visible', archived: false } }
      end

      it 'returns success response, then unprocessable_entity on second run' do
        get :create, params: params, format: :json
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq 'application/json'
        get :create, params: params, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq 'application/json'
      end
    end
  end

  describe '#edit' do
    context 'in JSON format' do
      let(:params) { { id: project_1.id } }

      it 'returns success response' do
        get :edit, params: params, format: :json
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq 'application/json'
      end
    end
  end

  describe '#update' do
    context 'in HTML format' do
      let(:params) do
        { id: project_1.id,
          project: { name: 'test project A1', team_id: team.id,
                     visibility: 'visible' } }
      end

      it 'returns redirect response' do
        put :update, params: params
        expect(response).to have_http_status(:redirect)
        expect(response.content_type).to eq 'text/html'
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
        expect(response.content_type).to eq 'text/html'
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
        expect(response.content_type).to eq 'application/json'
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
        expect(response.content_type).to eq 'text/html'
      end
    end
  end
end
