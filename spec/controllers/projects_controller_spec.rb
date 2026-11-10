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

  describe 'GET index (extra cases)' do
    # Lists::ProjectsService reads MyModuleStatusFlow.first, which only exists if the default flow was created.
    before { MyModuleStatusFlow.ensure_default }

    let(:folder) { create :project_folder, team: team }
    let!(:folder_project) do
      create :project, team: team, created_by: user, project_folder: folder,
                       default_public_user_role_id: owner_role.id
    end

    it 'scopes projects to the given folder and sets folder editing/navigator' do
      get :index, params: { project_folder_id: folder.id }, format: :json
      ids = JSON.parse(response.body)['data'].map { |d| d['id'] }
      expect(ids).to eq([folder_project.id.to_s])
      expect(assigns(:current_folder)).to eq(folder)
      expect(assigns(:inline_editable_title_config)).to include(params_group: 'project_folder', item_id: folder.id)
      expect(assigns(:navigator)).to include(id: folder.code)
    end

    it 'uses readable projects for non team managers' do
      allow(controller).to receive(:can_manage_team?).and_return(false)
      get :index, format: :json
      expect(response).to have_http_status(:success)
      expect(assigns(:projects).to_sql).to include('user_assignments')
      expect(assigns(:inline_editable_title_config)).to be_nil
    end
  end

  describe 'GET show (extra cases)' do
    it 'redirects to experiments in HTML format' do
      get :show, params: { id: project.id }
      expect(response).to redirect_to(experiments_path(project_id: project.id))
    end

    it 'returns not found for unknown project' do
      get :show, params: { id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_project?).and_return(false)
      get :show, params: { id: project.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET inventory_assigning_project_filter (with tasks)' do
    let!(:experiment) { create :experiment, project: project, created_by: user }
    let!(:my_module) { create :my_module, experiment: experiment, created_by: user }

    it 'returns projects that have assignable tasks' do
      get :inventory_assigning_project_filter, format: :json
      expect(response.media_type).to eq 'application/json'
      expect(JSON.parse(response.body)).to eq([[project.id, project.name]])
    end
  end

  describe 'POST create (forbidden)' do
    it 'returns forbidden without create permission' do
      allow(controller).to receive(:can_create_projects?).and_return(false)
      expect { post :create, params: { project: { name: 'Nope' } }, format: :json }
        .not_to(change { Project.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT update (JSON extra cases)' do
    let(:target) { projects.first }
    let(:action) { put :update, params: { id: target.id, project: project_params }, format: :json }

    def activity_count(type)
      Activity.where(type_of: Activity.type_ofs[type]).count
    end

    context 'when renaming and changing description' do
      let(:project_params) { { name: 'Renamed project', description: 'New description' } }

      it 'updates project and logs edit activity' do
        expect { action }.to change { activity_count(:edit_project) }.by(1)
        expect(target.reload.name).to eq('Renamed project')
        expect(target.description).to eq('New description')
        expect(JSON.parse(response.body)['status']).to eq('ok')
      end
    end

    context 'when archiving' do
      let(:project_params) { { archived: true } }

      it 'archives the project and logs archive activity' do
        expect { action }.to change { activity_count(:archive_project) }.by(1)
        expect(target.reload.archived?).to eq(true)
      end
    end

    context 'when archiving without archive permission' do
      let(:project_params) { { archived: true } }

      it 'refuses to archive' do
        # The archive permission check compares the boolean `archived` attribute with the
        # strings 'true'/'false', so it never triggers.
        pending 'bug: ProjectsController#update archive/restore permission check compares boolean to string'
        allow(controller).to receive(:can_archive_project?).and_return(false)
        action
        expect(response).to have_http_status(:unprocessable_entity)
        expect(target.reload.archived?).to eq(false)
      end
    end

    context 'when the project is archived' do
      let(:target) { create :project, :archived, team: team, created_by: user }
      let(:project_params) { { archived: false } }

      it 'cannot be restored through update (manage requires an active project)' do
        create_user_assignment(target, owner_role, user)
        action
        expect(response).to have_http_status(:forbidden)
        expect(target.reload.archived?).to eq(true)
      end
    end

    context 'when changing head of project' do
      let(:other_user) { create :user }
      let(:project_params) { { supervised_by_id: other_user.id } }

      before { target.update_column(:supervised_by_id, user.id) }

      it 'logs remove and set head of project activities' do
        expect { action }
          .to change { activity_count(:remove_head_of_project) }.by(1)
          .and change { activity_count(:set_head_of_project) }.by(1)
        expect(target.reload.supervised_by_id).to eq(other_user.id)
      end
    end

    context 'when changing start date' do
      let(:project_params) { { start_date: '2024-05-02' } }

      before { target.update_column(:start_date, Date.new(2024, 5, 1)) }

      it 'logs change start date activity' do
        expect { action }.to change { activity_count(:change_project_start_date) }.by(1)
      end
    end

    context 'when removing start date' do
      let(:project_params) { { start_date: '' } }

      before { target.update_column(:start_date, Date.new(2024, 5, 1)) }

      it 'logs remove start date activity' do
        expect { action }.to change { activity_count(:remove_project_start_date) }.by(1)
        expect(target.reload.start_date).to be_nil
      end
    end

    context 'when changing due date' do
      let(:project_params) { { due_date: '2024-06-02' } }

      before { target.update_column(:due_date, Date.new(2024, 6, 1)) }

      it 'logs change due date activity' do
        expect { action }.to change { activity_count(:change_project_due_date) }.by(1)
      end
    end

    context 'when removing due date' do
      let(:project_params) { { due_date: '' } }

      before { target.update_column(:due_date, Date.new(2024, 6, 1)) }

      it 'logs remove due date activity' do
        expect { action }.to change { activity_count(:remove_project_due_date) }.by(1)
      end
    end

    context 'without manage permission' do
      let(:project_params) { { name: 'Forbidden' } }

      it 'returns forbidden' do
        allow(controller).to receive(:can_manage_project?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
        expect(target.reload.name).not_to eq('Forbidden')
      end
    end
  end

  describe 'PUT update (HTML failure)' do
    it 'redirects back with error flash' do
      # The HTML error branch calls the undefined route helper `projects_archive_path`.
      pending 'bug: ProjectsController#update HTML error path uses undefined projects_archive_path'
      request.env['HTTP_REFERER'] = projects_url
      put :update, params: { id: projects.first.id, project: { name: '' } }
      expect(response).to redirect_to(projects_path)
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST archive_group / restore_group failures' do
    let(:archived_project) { create :project, :archived, team: team, created_by: user }

    it 'does not archive when archiving raises' do
      allow_any_instance_of(Project).to receive(:archive!).and_raise(StandardError, 'fail')
      post :archive_group, params: { project_ids: [project.id] }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(project.reload.archived?).to eq(false)
    end

    it 'does not restore when restoring raises' do
      allow_any_instance_of(Project).to receive(:restore!).and_raise(StandardError, 'fail')
      post :restore_group, params: { project_ids: [archived_project.id] }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(archived_project.reload.archived?).to eq(true)
    end

    it 'skips projects user cannot archive' do
      allow(controller).to receive(:can_archive_project?).and_return(false)
      post :archive_group, params: { project_ids: [project.id] }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(project.reload.archived?).to eq(false)
    end
  end

  describe 'GET head_of_project_users_list (with supervisor)' do
    it 'returns supervising users' do
      project.update_column(:supervised_by_id, user.id)
      get :head_of_project_users_list, format: :json
      expect(JSON.parse(response.body)['data'].map(&:first)).to eq([user.id])
    end
  end

  describe 'GET assigned_users_list (extra)' do
    it 'returns users assigned to the project' do
      get :assigned_users_list, params: { id: project.id }, format: :json
      expect(JSON.parse(response.body)['data'].map(&:first)).to include(user.id)
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_project?).and_return(false)
      get :assigned_users_list, params: { id: project.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
