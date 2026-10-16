# frozen_string_literal: true

require 'rails_helper'

describe MyModulesController, type: :controller do
  login_user
  include_context 'reference_project_structure'

  let!(:repository) { create :repository, created_by: user, team: team }
  let!(:repository_row) do
    create :repository_row, created_by: user, repository: repository
  end
  let!(:tag) { create :tag, team: team }

  before(:all) do
    MyModuleStatusFlow.ensure_default
  end

  describe 'GET index' do
    let(:action) { get :index, params: { experiment_id: experiment.id }, format: :json }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["data"]).to be_an(Array)
    end
  end

  describe 'GET assigned_users' do
    let(:action) { get :assigned_users, params: { id: my_module.id }, format: :json }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["data"]).to be_an(Array)
    end
  end

  describe 'POST create' do
    let(:action) do
      # I need custom route for create
      post :create, params: {
        experiment_id: experiment.id,
        my_module: {
          name: 'New Task',
          tag_ids: [tag.id],
          user_ids: [user.id]
        }
      }, format: :json
    end

    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["data"]).to include("id")
    end

    it 'creates a new my_module' do
      expect { action }.to change(MyModule, :count).by(1)
    end
  end

  describe 'GET show' do
    let(:action) { get :show, params: { id: my_module.id }, format: :json }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["data"]).to include("id" => my_module.id.to_s)
    end
  end

  describe 'GET protocol' do
    let(:action) { get :protocol, params: { id: my_module.id }, format: :json }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["data"]).to include("id" => my_module.protocol.id.to_s)
    end
  end

  describe 'GET actions_toolbar' do
    let(:action) { get :actions_toolbar, params: { items: [{ id: my_module.id }].to_json }, format: :json }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["actions"]).to be_an(Array)
    end
  end

  describe 'GET status_state' do
    let(:action) { get :status_state, params: { id: my_module.id }, format: :json }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
      expect(JSON.parse(response.body)["status_changing"]).to be_eql(false)
    end
  end

  describe 'GET status_partial' do
    let(:action) { get :status_partial, params: { id: my_module.id } }

    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(JSON.parse(response.body)).to have_key('html')
    end

    context 'when the user switched to another team in a different tab' do
      let(:other_team) { create :team, created_by: user, skip_user_assignments: true }

      before do
        create :user_assignment, user: user, assignable: other_team, user_role: owner_role
        user.update!(current_team_id: other_team.id)
      end

      it 'returns forbidden without switching the current team' do
        action
        expect(response).to have_http_status(:forbidden)
        expect(user.reload.current_team_id).to eq(other_team.id)
      end
    end
  end

  describe 'POST change_results_state' do
    let(:action) do
      post :change_results_state, params: { id: my_module.id, collapsed: true }, format: :json
    end
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end

  describe 'PATCH update_description' do
    let(:action) { patch :update_description, params: params, format: :json }
    let(:params) do
      { id: my_module.id, my_module: { description: 'description changed' } }
    end

    it 'calls create activity for changing task description' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :change_module_description)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PATCH update_protocol_description' do
    let(:action) { patch :update_protocol_description, params: params, format: :json }
    let(:params) do
      { id: my_module.id, protocol: { description: 'protocol description changed' } }
    end

    it 'calls create activity for changing task protocol description' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :protocol_description_in_task_edited)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    context 'when the protocol description is locked' do
      before { my_module.protocol.update!(description_locked: true) }

      it 'returns a forbidden response' do
        action
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not change the protocol description' do
        expect { action }.not_to(change { my_module.protocol.reload.description })
      end
    end
  end

  describe 'PATCH update_protocol' do
    let(:action) { patch :update_protocol, params: params, format: :json }

    context 'when changing the protocol description' do
      let(:params) do
        { id: my_module.id, protocol: { description: 'protocol description changed' } }
      end

      it 'calls create activity for changing task protocol description' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :protocol_description_in_task_edited)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end

      context 'when the protocol description is locked' do
        before { my_module.protocol.update!(description_locked: true) }

        it 'returns a forbidden response' do
          action
          expect(response).to have_http_status(:forbidden)
        end

        it 'does not change the protocol description' do
          expect { action }.not_to(change { my_module.protocol.reload.description })
        end
      end
    end

    context 'when changing the protocol name' do
      let(:params) do
        { id: my_module.id, protocol: { name: 'Updated protocol name' } }
      end

      it 'calls create activity for changing task protocol name' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :protocol_name_in_task_edited)))
        action
      end
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }

    context 'when changing task description' do
      let(:params) do
        { id: my_module.id, my_module: { description: 'description changed' } }
      end

      it 'calls create activity for changing task description' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :change_module_description)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when setting due_date' do
      let(:params) do
        { id: my_module.id, my_module: { due_date: '2019-03-21 23:59' } }
      end

      it 'calls create activity for setting due date' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :set_task_due_date)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when deleting due_date' do
      let(:params) { { id: my_module.id, my_module: { due_date: '' } } }
      let(:my_module) do
        create :my_module, :with_due_date, experiment: experiment, created_by: experiment.created_by
      end

      it 'calls create activity for removing due date' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :remove_task_due_date)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when updating due_date' do
      let(:params) do
        { id: my_module.id, my_module: { due_date: '2019-02-21 23:59' } }
      end
      let(:my_module) do
        create :my_module, :with_due_date, experiment: experiment, created_by: experiment.created_by
      end

      it 'calls create activity for changing due date' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :change_task_due_date)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'PUT update_state' do
    let(:action) { put :update_state, params: params, format: :json }
    let(:my_module_id) { my_module.id }
    let(:status_id) { 'some-state-id' }
    let(:params) do
      {
        id: my_module_id,
        my_module: { status_id: status_id }
      }
    end

    before(:all) do
      MyModuleStatusFlow.ensure_default
    end

    context 'when states updated' do
      let(:status_id) { my_module.my_module_status.next_status.id }

      it 'changes status' do
        action

        expect(my_module.reload.my_module_status.id).to be_eql(status_id)
      end

      it 'creates activity' do
        expect { action }.to(change { Activity.all.count }.by(1))
      end
    end

    context 'when status not exist' do
      let(:status_id) { -1 }

      it 'renders 422' do
        my_module.my_module_status_flow
        action

        expect(response).to have_http_status 422
      end
    end

    context 'when status not correct' do
      let(:status_id) { my_module.my_module_status.next_status.next_status.id }

      it 'renders 422' do
        action

        expect(response).to have_http_status 422
      end
    end

    context 'when user does not have permissions' do
      it 'renders 403' do
        UserAssignment.where(user: user, assignable: my_module).destroy_all
        action

        expect(response).to have_http_status 403
      end
    end

    context 'when my_module not found' do
      let(:my_module_id) { -1 }

      it 'renders 404' do
        action

        expect(response).to have_http_status 404
      end
    end
  end

  describe 'POST restore_tasks' do
    let(:action) { post :restore_group, params: params }
    let(:params) do
      {
        id: experiment.id,
        my_modules_ids: [task1.id, task2.id, task3.id]
      }
    end
    let(:task1) { create :my_module, :archived, experiment: experiment, created_by: experiment.created_by }
    let(:task2) { create :my_module, :archived, experiment: experiment, created_by: experiment.created_by }
    let(:task3) { create :my_module, :archived, experiment: experiment, created_by: experiment.created_by }
    let(:user) { controller.current_user }

    context 'when tasks are restored' do
      it 'tasks are active' do
        action

        expect(task1.reload.active?).to be_truthy
        expect(task2.reload.active?).to be_truthy
        expect(task3.reload.active?).to be_truthy
      end

      it 'calls create activity service 3 times' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: :restore_module))).exactly(3).times

        action
      end

      it 'adds activity in DB' do
        expect { action }.to(change { Activity.count }.by(3))
      end

      it 'renders 302' do
        action

        expect(response).to have_http_status(302)
      end
    end

    context 'when tasks are not restored' do
      context 'when one task is invalid' do
        before do
          task3.name = Faker::Lorem.characters(number: 300)
          task3.save(validate: false)
        end

        it 'returns 302' do
          action

          expect(response).to have_http_status(302)
        end

        it 'only 2 activities added in DB' do
          expect { action }.to(change { Activity.count }.by(2))
        end

        it 'one task is still archived' do
          action

          expect(task1.reload.active?).to be_truthy
          expect(task2.reload.active?).to be_truthy
          expect(task3.reload.active?).to be_falsey
        end
      end

      context 'when user does not have permissions for one task' do
        before do
          task3.restore!(user)
        end

        it 'returns 302' do
          action

          expect(response).to have_http_status(302)
        end

        it 'only 2 activities added in DB' do
          expect { action }.to(change { Activity.count }.by(2))
        end

        it 'tasks are restored' do
          action

          expect(task1.reload.active?).to be_truthy
          expect(task2.reload.active?).to be_truthy
          expect(task3.reload.active?).to be_truthy
        end
      end
    end
  end

  describe 'POST favorite' do
    let(:action) { post :favorite, params: { id: my_module.id } }

    it 'creates a favorite' do
      expect(user.favorites.exists?(item: my_module )).to eq(false)
      action
      expect(user.favorites.exists?(item: my_module )).to eq(true)
    end
  end

  describe 'POST unfavorite' do
    let(:action) { post :unfavorite, params: { id: my_module.id } }

    it 'removes a favorite' do
      Favorite.create!(user: user, item: my_module, team: my_module.team)
      action
      expect(user.favorites.exists?(item: my_module )).to eq(false)
    end
  end

  describe 'GET index (HTML)' do
    let(:action) { get :index, params: { experiment_id: experiment.id } }

    it 'saves table view type and sets navigator for the experiment' do
      action
      expect(response).to have_http_status(:success)
      expect(experiment.current_view_state(user).state['my_modules']['view_type']).to eq('table')
      expect(assigns(:navigator)).to include(id: experiment.code, archived: false)
      expect(assigns(:inline_editable_title_config)).to include(params_group: 'experiment', item_id: experiment.id)
    end

    context 'when user cannot read the experiment' do
      before { allow(controller).to receive(:can_read_experiment?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET index (missing experiment)' do
    it 'returns not found' do
      # load_experiment calls render_404 but continues and calls @experiment.project on nil.
      pending 'bug: MyModulesController#load_experiment does not halt after render_404 (NoMethodError on nil)'
      get :index, params: { experiment_id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET assigned_users (forbidden)' do
    before { allow(controller).to receive(:can_read_my_module?).and_return(false) }

    it 'returns forbidden' do
      get :assigned_users, params: { id: my_module.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST create (extra cases)' do
    let(:other_user) { create :user }
    let(:params) do
      { experiment_id: experiment.id, my_module: { name: 'Designated task', user_ids: [other_user.id] } }
    end

    context 'when designating another experiment member' do
      before { create_user_assignment(experiment, owner_role, other_user, user) }

      it 'designates the user and logs designation activity' do
        expect { post :create, params: params, format: :json }
          .to change { Activity.where(type_of: Activity.type_ofs[:designate_user_to_my_module]).count }.by(1)
        new_module = MyModule.find_by(name: 'Designated task')
        expect(new_module.designated_users).to include(other_user)
      end
    end

    context 'when user cannot designate users' do
      before { allow(controller).to receive(:can_designate_users_to_new_task?).and_return(false) }

      it 'designates only the current user' do
        post :create, params: params, format: :json
        expect(response).to have_http_status(:success)
        expect(MyModule.find_by(name: 'Designated task').designated_users).to contain_exactly(user)
      end
    end

    context 'when the name is invalid' do
      let(:params) { { experiment_id: experiment.id, my_module: { name: 'a' * 300 } } }

      it 'returns unprocessable entity and does not create a task' do
        expect { post :create, params: params, format: :json }.not_to(change { MyModule.count })
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('name')
      end
    end

    context 'when user has no create permissions' do
      before { allow(controller).to receive(:can_create_experiment_tasks?).and_return(false) }

      it 'returns forbidden' do
        expect { post :create, params: params, format: :json }.not_to(change { MyModule.count })
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET show (HTML)' do
    it 'returns JSON with html key' do
      get :show, params: { id: my_module.id }, format: :html
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('html')
    end

    it 'returns 404 for unknown task' do
      get :show, params: { id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_my_module?).and_return(false)
      get :show, params: { id: my_module.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET description' do
    let(:action) { get :description, params: { id: my_module.id }, format: :json }

    it 'returns html and title' do
      # The action renders partial 'my_modules/_description', which no longer exists in app/views,
      # so it raises ActionView::MissingTemplate (500) for any format.
      pending 'bug: my_modules#description renders missing partial my_modules/_description'
      get :description, params: { id: my_module.id }
      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body.keys).to include('html', 'title')
      expect(body['title']).to include(my_module.name)
    end

    it 'returns forbidden without manage permission' do
      allow(controller).to receive(:can_manage_my_module?).and_return(false)
      action
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET current_status (forbidden)' do
    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_my_module?).and_return(false)
      get :current_status, params: { id: my_module.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET status_partial' do
    it 'returns html' do
      get :status_partial, params: { id: my_module.id }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('html')
    end
  end

  describe 'GET status_state with repository snapshot error' do
    before do
      my_module.update_column(:last_transition_error, { 'type' => 'repository_snapshot', 'message' => 'boom' })
    end

    it 'puts the error into flash' do
      get :status_state, params: { id: my_module.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(flash[:repository_snapshot_error]).to include('type' => 'repository_snapshot')
      expect(JSON.parse(response.body)['status_changing']).to eq(false)
    end
  end

  describe 'GET canvas_dropdown_menu' do
    it 'returns html and computes experiment manageability' do
      get :canvas_dropdown_menu, params: { id: my_module.id }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('html')
      expect(assigns(:experiment_managable)).to eq(true)
    end
  end

  describe 'GET activities' do
    before do
      Activities::CreateActivityService.call(activity_type: :rename_task, owner: user, team: team,
                                             project: project, subject: my_module,
                                             message_items: { my_module: my_module.id })
    end

    it 'renders HTML and groups activities by date' do
      get :activities, params: { id: my_module.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:grouped_activities).values.flatten.map(&:subject)).to include(my_module)
      expect(assigns(:navigator)).to include(id: my_module.code)
      expect(assigns(:inline_editable_title_config)).to include(params_group: 'my_module', item_id: my_module.id)
    end

    it 'returns JSON with activities html and next page' do
      get :activities, params: { id: my_module.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).keys).to include('activities_html', 'next_page')
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_my_module?).and_return(false)
      get :activities, params: { id: my_module.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET activities_tab' do
    it 'returns html with last activities' do
      # MyModule#last_activities only finds legacy activities linked via my_module_id
      # (new activities use subject and fail validation with my_module_id set).
      legacy = Activity.new(type_of: :create_module, owner: user, team: team, project: project,
                            my_module: my_module, message_items: {})
      legacy.save!(validate: false)
      get :activities_tab, params: { id: my_module.id }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('html')
      expect(assigns(:activities)).to include(legacy)
    end
  end

  describe 'GET due_date' do
    it 'returns html and title' do
      get :due_date, params: { id: my_module.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).keys).to include('html', 'title')
    end

    it 'returns forbidden without manage permission' do
      allow(controller).to receive(:can_manage_my_module?).and_return(false)
      get :due_date, params: { id: my_module.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT update (extra cases)' do
    let(:action) { put :update, params: params, format: :json }

    context 'when archiving the task' do
      let(:params) { { id: my_module.id, my_module: { archived: 'true' } } }

      it 'archives the task' do
        action
        expect(response).to have_http_status(:success)
        expect(my_module.reload.archived?).to eq(true)
        expect(JSON.parse(response.body)['alerts']).to be_an(Array)
      end

      it 'returns forbidden without archive permission' do
        allow(controller).to receive(:can_archive_my_module?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
        expect(my_module.reload.archived?).to eq(false)
      end
    end

    context 'when output is object' do
      let(:params) { { id: my_module.id, output: 'object', my_module: { name: 'Renamed task' } } }

      it 'renames the task, logs activity and returns serialized task' do
        expect { action }.to change { Activity.where(type_of: Activity.type_ofs[:rename_task]).count }.by(1)
        expect(my_module.reload.name).to eq('Renamed task')
        expect(JSON.parse(response.body)['data']).to include('id' => my_module.id.to_s)
      end
    end

    context 'when name is invalid' do
      let(:params) { { id: my_module.id, my_module: { name: 'a' * 300 } } }

      it 'returns unprocessable entity' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('name')
      end
    end

    context 'when user cannot manage the task' do
      let(:params) { { id: my_module.id, my_module: { name: 'Renamed task' } } }

      it 'returns forbidden' do
        allow(controller).to receive(:can_manage_my_module?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
        expect(my_module.reload.name).not_to eq('Renamed task')
      end
    end

    context 'when start date is set' do
      let(:params) { { id: my_module.id, my_module: { started_on: '2024-03-21 10:00' } } }

      it 'logs set start date activity' do
        expect { action }.to change { Activity.where(type_of: Activity.type_ofs[:set_task_start_date]).count }.by(1)
        expect(my_module.reload.started_on.strftime('%Y-%m-%d')).to eq('2024-03-21')
      end
    end

    context 'when start date is changed' do
      let(:params) { { id: my_module.id, my_module: { started_on: '2024-03-22 10:00' } } }

      before { my_module.update_column(:started_on, Time.zone.parse('2024-03-01 10:00')) }

      it 'logs change start date activity' do
        expect { action }
          .to change { Activity.where(type_of: Activity.type_ofs[:change_task_start_date]).count }.by(1)
      end
    end

    context 'when start date is removed' do
      let(:params) { { id: my_module.id, my_module: { started_on: '' } } }

      before { my_module.update_column(:started_on, Time.zone.parse('2024-03-01 10:00')) }

      it 'logs remove start date activity' do
        expect { action }
          .to change { Activity.where(type_of: Activity.type_ofs[:remove_task_start_date]).count }.by(1)
        expect(my_module.reload.started_on).to be_nil
      end
    end

    context 'when user cannot update start date' do
      let(:params) { { id: my_module.id, my_module: { started_on: '2024-03-21 10:00' } } }

      it 'returns forbidden' do
        allow(controller).to receive(:can_update_my_module_start_date?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PATCH update_description (extra cases)' do
    let(:action) do
      patch :update_description, params: { id: my_module.id, my_module: { description: 'new' } }, format: :json
    end

    it 'returns rendered html and updates description' do
      action
      expect(JSON.parse(response.body)).to have_key('html')
      expect(my_module.reload.description).to eq('new')
    end

    it 'returns unprocessable entity when update fails' do
      allow_any_instance_of(MyModule).to receive(:update).and_return(false)
      action
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns forbidden without description permission' do
      allow(controller).to receive(:can_update_my_module_description?).and_return(false)
      action
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH update_protocol_description (failure)' do
    it 'returns unprocessable entity when update fails' do
      allow_any_instance_of(Protocol).to receive(:update).and_return(false)
      patch :update_protocol_description,
            params: { id: my_module.id, protocol: { description: 'x' } }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH update_protocol (invalid)' do
    it 'returns unprocessable entity for too long name' do
      patch :update_protocol, params: { id: my_module.id, protocol: { name: 'a' * 300 } }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key('name')
      expect(my_module.protocol.reload.name).not_to eq('a' * 300)
    end

    it 'returns forbidden without manage permission' do
      allow(controller).to receive(:can_manage_my_module?).and_return(false)
      patch :update_protocol, params: { id: my_module.id, protocol: { name: 'x' } }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET protocols' do
    it 'renders the protocols page with protocol and experiment tasks' do
      get :protocols, params: { id: my_module.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:protocol)).to eq(my_module.protocol)
      expect(assigns(:experiment_my_modules)).to include(my_module)
      expect(assigns(:breadcrumbs_items).map { |i| i[:label] }).to include(project.name, experiment.name)
    end

    context 'when experiment is archived' do
      before { experiment.update_columns(archived: true, archived_on: Time.zone.now, archived_by_id: user.id) }

      it 'loads all experiment tasks and marks navigator as archived' do
        get :protocols, params: { id: my_module.id }
        expect(assigns(:experiment_my_modules)).to include(my_module)
        expect(assigns(:navigator)[:archived]).to eq(true)
      end
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_my_module?).and_return(false)
      get :protocols, params: { id: my_module.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET archive' do
    let!(:archived_result) { create :result, :archived, my_module: my_module, user: user }

    it 'renders archived results' do
      get :archive, params: { id: my_module.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:archived_results)).to include(archived_result)
    end
  end

  describe 'POST restore_group (table view)' do
    let(:archived_task) { create :my_module, :archived, experiment: experiment, created_by: user }

    it 'returns JSON message when tasks are restored' do
      post :restore_group, params: { id: experiment.id, my_modules_ids: [archived_task.id], view: 'table' }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('message')
      expect(archived_task.reload.active?).to eq(true)
    end

    it 'returns error when no task could be restored' do
      allow(controller).to receive(:can_restore_my_module?).and_return(false)
      post :restore_group, params: { id: experiment.id, my_modules_ids: [archived_task.id], view: 'table' }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key('error')
      expect(archived_task.reload.archived?).to eq(true)
    end

    it 'sets flash error and redirects when nothing restored in canvas view' do
      allow(controller).to receive(:can_restore_my_module?).and_return(false)
      post :restore_group, params: { id: experiment.id, my_modules_ids: [archived_task.id] }
      expect(response).to redirect_to(module_archive_experiment_path(experiment))
      expect(flash[:error]).to be_present
    end

    it 'returns forbidden without experiment read permission' do
      allow(controller).to receive(:can_read_experiment?).and_return(false)
      post :restore_group, params: { id: experiment.id, my_modules_ids: [archived_task.id], view: 'table' }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT update_state without status' do
    it 'returns 404 when task has no status' do
      my_module.update_column(:my_module_status_id, nil)
      put :update_state, params: { id: my_module.id, my_module: { status_id: 1 } }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET permissions' do
    it 'returns permissions for the task' do
      get :permissions, params: { id: my_module.id }, format: :json
      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body.keys).to contain_exactly('editable', 'moveable', 'archivable', 'restorable')
      expect(body['editable']).to eq(true)
      expect(body['restorable']).to eq(false)
    end
  end

  describe 'POST actions_toolbar without items' do
    it 'returns empty actions list' do
      post :actions_toolbar, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['actions']).to eq([])
    end
  end

  describe 'GET provisioning_status' do
    it 'returns provisioning status' do
      my_module.update_column(:provisioning_status, MyModule.provisioning_statuses[:in_progress])
      get :provisioning_status, params: { id: my_module.id }, format: :json
      expect(JSON.parse(response.body)['provisioning_status']).to eq('in_progress')
    end
  end

  describe 'GET inventory_assigning_my_module_filter' do
    it 'returns assignable tasks for the experiment' do
      get :inventory_assigning_my_module_filter, params: { experiment_id: experiment.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to include([my_module.id, my_module.name])
    end

    it 'returns 404 for an experiment without assignable tasks' do
      get :inventory_assigning_my_module_filter, params: { experiment_id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST change_results_state with results' do
    let!(:result) { create :result, my_module: my_module, user: user }

    it 'stores collapsed state for each result' do
      post :change_results_state, params: { id: my_module.id, collapsed: true }, format: :json
      expect(JSON.parse(response.body)['status']).to eq('ok')
      expect(user.user_settings.find_by(key: 'result_states').value).to include(result.id.to_s => true)
    end

    it 'stores expanded state when collapsed param missing' do
      post :change_results_state, params: { id: my_module.id }, format: :json
      expect(user.user_settings.find_by(key: 'result_states').value).to include(result.id.to_s => false)
    end
  end

  describe 'tagging' do
    let(:team_tag) { create :tag, team: team }

    it 'tags the task and logs activity' do
      expect do
        post :tag_resource, params: { id: my_module.id, tag_id: team_tag.id }, format: :json
      end.to change { Activity.where(type_of: Activity.type_ofs[:add_task_tag]).count }.by(1)
      expect(JSON.parse(response.body)['tag']).to include('id' => team_tag.id)
      expect(my_module.tags.reload).to include(team_tag)
    end

    it 'untags the task and logs activity' do
      my_module.taggings.create!(tag: team_tag, created_by: user)
      expect do
        post :untag_resource, params: { id: my_module.id, tag_id: team_tag.id }, format: :json
      end.to change { Activity.where(type_of: Activity.type_ofs[:remove_task_tag]).count }.by(1)
      expect(my_module.tags.reload).not_to include(team_tag)
    end

    it 'returns forbidden without tag manage permission' do
      allow(controller).to receive(:can_manage_my_module_tags?).and_return(false)
      post :tag_resource, params: { id: my_module.id, tag_id: team_tag.id }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(my_module.tags.reload).not_to include(team_tag)
    end
  end
end
