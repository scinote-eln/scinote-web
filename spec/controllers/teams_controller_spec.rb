# frozen_string_literal: true

require 'rails_helper'

describe TeamsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }

  describe 'POST export_projects' do
    before do
      view_response = '<div class="content-pane" id="report-new"><div class="report-container"><div id="report-content"></div></div></div>'
      proxy_manager = Warden::Manager.new({})
      proxy = Warden::Proxy.new({}, proxy_manager)

      renderer_double = instance_double(ActionController::Renderer,
                                        render: view_response.dup,
                                        render_to_string: view_response.dup)

      allow(Warden::Manager).to receive(:new).and_return(proxy_manager)
      allow(Warden::Proxy).to receive(:new).with({}, proxy_manager).and_return(proxy)
      allow(ApplicationController.renderer).to receive(:new).with({ warden: proxy }).and_return(renderer_double)
      allow(ApplicationController).to receive(:render)
    end

    let!(:first_project) { create :project, team: team, created_by: user }
    let!(:second_project) { create :project, team: team, created_by: user }
    let(:params) do
      {
        id: team.id,
        project_ids: [first_project.id, second_project.id]
      }
    end
    let(:action) { post :export_projects, params: params, format: :json }

    it 'calls create activity for inviting user' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :export_projects)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
  describe 'user and team lists' do
    let!(:other_team) { create :team, created_by: user, name: 'AAA other' }
    let!(:teammate) { create :user, full_name: 'Teammate Person' }

    before { create_user_assignment(team, UserRole.find_by(name: I18n.t('user_roles.predefined.normal_user')) || create(:normal_user_role), teammate) }

    it 'GET visible_teams lists the teams of the user ordered by name' do
      get :visible_teams, format: :json
      expect(response).to have_http_status(:success)
      names = JSON.parse(response.body)['data'].map { |t| t['attributes']['name'] }
      expect(names).to eq user.teams.order(:name).pluck(:name)
      expect(names).to include('AAA other', team.name)
    end

    it 'GET visible_users lists users of all own teams' do
      get :visible_users, format: :json
      expect(response.body).to include('Teammate Person')
    end

    it 'GET visible_users can be limited to chosen teams' do
      get :visible_users, params: { teams: [other_team.id] }, format: :json
      expect(response.body).not_to include('Teammate Person')
    end

    it 'GET current_team_users lists users of the current team' do
      user.update!(current_team_id: team.id)
      get :current_team_users, format: :json
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Teammate Person')
    end
  end

  describe 'GET sidebar' do
    it 'returns the sidebar html' do
      get :sidebar, params: { id: team.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('html')
    end

    it 'loads the requested project folder' do
      folder = create :project_folder, team: team
      get :sidebar, params: { id: team.id, project_folder_id: folder.id }, format: :json
      expect(controller.current_folder).to eq folder
    end

    it 'returns 404 for a team the user is not a member of' do
      get :sidebar, params: { id: create(:team).id }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'export_projects' do
    let!(:project) { create :project, team: team, created_by: user }

    before do
      allow(TeamZipExportJob).to receive(:perform_later)
    end

    it 'enqueues the export job and renders a flash message' do
      post :export_projects, params: { id: team.id, project_ids: [project.id] }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['flash']).to eq I18n.t('projects.export_projects.success_flash')
      expect(TeamZipExportJob).to have_received(:perform_later)
        .with(user_id: user.id, params: { team_id: team.id, project_ids: [project.id] })
    end

    it 'exports projects of the given folders' do
      folder = create :project_folder, team: team
      project.update!(project_folder: folder)
      post :export_projects, params: { id: team.id, project_folder_ids: [folder.id] }, format: :json
      expect(TeamZipExportJob).to have_received(:perform_later)
        .with(user_id: user.id, params: { team_id: team.id, project_ids: [project.id] })
    end

    it 'is forbidden when the user cannot export a project' do
      allow(controller).to receive(:can_export_project?).and_return(false)
      post :export_projects, params: { id: team.id, project_ids: [project.id] }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(TeamZipExportJob).not_to have_received(:perform_later)
    end

    it 'does nothing when the daily export limit is reached' do
      allow_any_instance_of(User).to receive(:has_available_exports?).and_return(false)
      expect { post :export_projects, params: { id: team.id, project_ids: [project.id] }, format: :json }
        .not_to(change { Activity.count })
      expect(TeamZipExportJob).not_to have_received(:perform_later)
    end
  end

  describe 'GET export_projects_modal' do
    let!(:project) { create :project, team: team, created_by: user }

    # bug: app/views/projects/export/_modal and _error do not exist, so both success branches raise
    it 'fails to render the confirmation modal (missing partial)' do
      expect { get :export_projects_modal, params: { id: team.id, project_ids: [project.id] }, format: :json }
        .to raise_error(ActionView::MissingTemplate, /projects\/export\/_modal/)
    end

    it 'fails to render the limit error (missing partial)' do
      allow_any_instance_of(User).to receive(:has_available_exports?).and_return(false)
      expect { get :export_projects_modal, params: { id: team.id, project_ids: [project.id] }, format: :json }
        .to raise_error(ActionView::MissingTemplate, /projects\/export\/_error/)
    end

    it 'returns 422 when there is nothing to export' do
      get :export_projects_modal, params: { id: team.id }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['flash']).to eq I18n.t('projects.export_projects.zero_projects_flash')
    end
  end

  describe 'automations' do
    it 'GET automations renders the page with the team tab' do
      get :automations, params: { id: team.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:active_tab)).to eq :automations
    end

    it 'GET automation_settings returns settings and the update url' do
      get :automation_settings, params: { id: team.id }, format: :json
      body = JSON.parse(response.body)
      expect(body['teamName']).to eq team.name
      expect(body).to include('teamAutomationGroups', 'teamSettings', 'updateUrl')
    end

    it 'PUT update_automation_settings stores the settings' do
      put :update_automation_settings,
          params: { id: team.id, team: { team_automation_settings: { 'task_status_in_progress' => { 'on_step_completion' => 'true' } } } },
          format: :json
      expect(response).to have_http_status(:success)
      expect(team.reload.settings['team_automation_settings']).to be_present
    end

    it 'PUT update_automation_settings returns errors when saving fails' do
      allow_any_instance_of(Team).to receive(:save).and_return(false)
      put :update_automation_settings,
          params: { id: team.id, team: { team_automation_settings: { 'a' => { 'b' => 'true' } } } },
          format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'team settings' do
    it 'GET available_settings returns settings for the mode' do
      get :available_settings, params: { id: team.id, mode: 'general' }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['sharing']['task_sharing_enabled']).to include('can_update' => true)
    end

    it 'PUT update_setting changes a setting and logs an activity' do
      expect do
        put :update_setting, params: { id: team.id, mode: 'general', section: 'sharing',
                                       key: 'task_sharing_enabled', value: true }, as: :json
      end.to change { Activity.where(type_of: :team_sharing_tasks_enabled).count }.by(1)
      expect(response).to have_http_status(:ok)
      expect(team.reload.settings['task_sharing_enabled']).to be true
    end

    it 'PUT update_setting logs a disabled activity' do
      put :update_setting, params: { id: team.id, mode: 'general', section: 'sharing',
                                     key: 'task_sharing_enabled', value: false }, as: :json
      expect(Activity.where(type_of: :team_sharing_tasks_disabled).count).to eq 1
    end

    it 'PUT update_setting is forbidden when the user cannot change the setting' do
      viewer_role = create :viewer_role
      team.user_assignments.find_by(user: user).update!(user_role: viewer_role)
      put :update_setting, params: { id: team.id, mode: 'general', section: 'sharing',
                                     key: 'task_sharing_enabled', value: true }, as: :json
      expect(response).to have_http_status(:forbidden).or have_http_status(:redirect)
      expect(team.reload.settings['task_sharing_enabled']).not_to be true
    end
  end
end
