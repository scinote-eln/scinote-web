# frozen_string_literal: true

require 'rails_helper'

describe ExperimentsController, type: :controller do
  login_user
  include_context 'reference_project_structure'

  let(:archived_experiment) do
        create :experiment,
               archived: true,
               archived_by: (create :user),
               archived_on: Time.zone.now,
               project: project,
               created_by: project.created_by
      end


  describe 'GET index' do
    before(:all) do
      MyModuleStatusFlow.ensure_default
    end

    let(:action) { get :index, params: { project_id: experiment.project.id, page: 1, per_page: 20 }, format: :json }
    let(:action_html) { get :index, params: { project_id: experiment.project.id, page: 1, per_page: 20 }, format: :html }

    it 'correct JSON format' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(1)
      expect(parsed_response['data'].first['id']).to eq(experiment.id.to_s)
    end

    it 'correct HTML format' do
      action_html  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'text/html'
    end
  end

  describe 'GET show' do
    let(:action) { get :show, params: { project_id: experiment.project.id, id: experiment.id }, format: :json }

    it 'correct JSON format' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).to eq(experiment.id.to_s)
    end
  end

  describe 'GET assigned_users' do
    let(:action) { get :assigned_users, params: { id: experiment.id }, format: :json }

    it 'correct JSON format' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(1)
      expect(parsed_response['data'].first['id']).to eq(user.id.to_s)
    end
  end


  describe 'GET canvas' do
    let(:action) { get :canvas, params: { id: experiment.id } }
    it 'successful call' do
      action  
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET my_modules' do
    let(:action) { get :my_modules, params: { id: experiment.id }, format: :json }

    it 'correct JSON format' do
      action  
      expect(response).to have_http_status(:found)
      expect(response.media_type).to eq 'text/html'
    end
  end

  describe 'PUT view_type' do
    shared_examples 'redirects with HTML response' do
      it 'redirects with 302 and HTML' do
        action
        expect(response).to have_http_status(:found)
        expect(response.media_type).to eq('text/html')
      end
    end

    context 'archived mode' do
      let(:action) { put :view_type, params: { id: experiment.id, experiment: { view_type: view_type }, view_mode: 'archived' }, format: :json }

      context 'canvas view' do
        let(:view_type) { 'canvas' }
        include_examples 'redirects with HTML response'
      end

      context 'table view' do
        let(:view_type) { 'table' }
        include_examples 'redirects with HTML response'
      end
    end

    context 'active mode' do
      let(:action) { put :view_type, params: { id: experiment.id, experiment: { view_type: view_type } }, format: :json }

      context 'canvas view' do
        let(:view_type) { 'canvas' }
        include_examples 'redirects with HTML response'
      end

      context 'table view' do
        let(:view_type) { 'table' }
        include_examples 'redirects with HTML response'
      end
    end
  end

  describe 'GET module_archive' do
    let(:action) { get :module_archive, params: { id: experiment.id } }
    it 'successful call' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'text/html'
    end
  end

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { project_id: project.id,
        experiment: { name: 'test experiment A1',
                      description: 'test description one' } }
    end

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :create_experiment))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params }

    context 'when editing experiment' do
      let(:params) do
        {
          id: experiment.id,
          experiment: { name: 'new_title', description: 'new description' }
        }
      end

      it 'calls create activity for editing experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :edit_experiment)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

     context 'when renaming experiment' do
      let(:params) do
        {
          id: experiment.id,
          experiment: { name: 'new_title' }
        }
      end

      it 'calls create activity for editing experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :rename_experiment)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when archiving experiment' do
      let(:params) {{ id: archived_experiment.id, experiment: { archived: false }}}

      it 'calls create activity for unarchiving experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
            .with(hash_including(activity_type: :restore_experiment)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'GET archive' do
    let(:action) { get :archive, params: params, format: :json }
    let(:params) do
      { id: experiment.id,
        experiment: { archived: false } }
    end
    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :archive_experiment))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'POST archive_group' do
    let(:action) { post :archive_group, params: { project_id: experiment.project.id, experiment_ids: experiment_list } }

    context 'when valid experiments' do
      let(:experiment_list) { [experiment.id] }
      it 'archive experiments' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :archive_experiment))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when not valid experiments' do
      let(:experiment_list) { [-1] }
      it 'archive experiments' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq 'application/json'
      end
    end
  end

  describe 'POST restore_group' do
    let(:action) { post :restore_group, params: { project_id: archived_experiment.project.id, experiment_ids: experiment_list } }

    context 'when valid experiments' do
      let(:experiment_list) { [archived_experiment.id] }
      it 'restore experiments' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :restore_experiment))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when not valid experiments' do
      let(:experiment_list) { [-1] }
      it 'restore experiments' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq 'application/json'
      end
    end
  end

  describe 'GET projects_to_clone' do
    let(:action) { get :projects_to_clone, params: { id: experiment.id, query: ''}, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(experiment.project.team.projects.active.count)
    end
  end

  describe 'GET projects_to_move' do
    let(:action) { get :projects_to_move, params: { id: experiment.id, query: ''}, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(experiment.project.team.projects.active.count - 1)
    end
  end

  describe 'GET experiments_to_move' do
    let(:action) { get :experiments_to_move, params: { project_id: experiment.project.id, query: ''}, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(experiment.project.experiments.active.count)
    end
  end

  describe 'POST clone' do
    let!(:project_second) { create(:project, team: team, created_by: user) }
    let(:action) { post :clone, params: { project_id: experiment.project.id, id: experiment.id, experiment: { project_id: project_second.id }} }

    it 'creates a clone' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
    end
  end

  describe 'POST move' do
    let(:project_second) { create(:project, team: team, created_by: user) }
    let(:action) { post :move, params: params }

    context 'when moving experiments to another project' do
      let(:params) {{ project_id: project_second.id, ids: [experiment.id] }}

      it 'returns success JSON' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end
    end

    context 'when moving experiments to the same project (invalid)' do
      let(:params) {{ project_id: experiment.project.id, ids: [experiment.id] }}

      it 'returns unprocessable entity' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST move_modules' do
    let!(:experiment_second) { create(:experiment, project_id: project.id, created_by: user) }
    let(:action) { post :move_modules, params: { id: experiment.id, to_experiment_id: experiment_second.id, my_module_ids: [my_module.id] }}

    it 'move tasks succesfully' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
    end
  end

  describe 'POST archive_my_modules' do
    let!(:experiment_second) { create(:experiment, project_id: project.id, created_by: user) }
    let(:action) { post :archive_my_modules, params: { id: experiment.id, my_modules: [my_module.id] }}

    it 'archive tasks succesfully' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
    end
  end

  describe 'GET inventory_assigning_experiment_filter' do
    let(:action) { get :inventory_assigning_experiment_filter, params: { project_id: project.id }, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      expect(response.body).not_to be_empty
    end
  end

   describe 'POST batch_clone_my_modules' do
    let(:action) { post :batch_clone_my_modules, params: { id: experiment.id, my_module_ids: [my_module.id] }}

    it 'move tasks succesfully' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      expect(response.body).not_to be_empty
    end
  end

  describe 'POST favorite' do
    let(:action) { post :favorite, params: { id: experiment.id } }

    it 'creates a favorite' do
      expect(user.favorites.exists?(item: experiment )).to eq(false)
      action
      expect(user.favorites.exists?(item: experiment )).to eq(true)
    end
  end

  describe 'POST unfavorite' do
    let(:action) { post :unfavorite, params: { id: experiment.id } }

    it 'removes a favorite' do
      Favorite.create!(user: user, item: experiment, team: experiment.team)
      action
      expect(user.favorites.exists?(item: experiment )).to eq(false)
    end
  end

  describe 'GET show (forbidden)' do
    it 'returns forbidden without read permissions' do
      allow(controller).to receive(:can_read_experiment?).and_return(false)
      get :show, params: { id: experiment.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for unknown experiment' do
      get :show, params: { id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET index (missing project)' do
    it 'returns not found' do
      # load_project calls render_404 but then keeps going and calls @project.team on nil.
      pending 'bug: ExperimentsController#load_project does not halt after render_404 (NoMethodError on nil)'
      get :index, params: { project_id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET canvas (extra cases)' do
    it 'saves canvas view type and loads active tasks' do
      get :canvas, params: { id: experiment.id }
      expect(experiment.current_view_state(user).state['my_modules']['view_type']).to eq('canvas')
      expect(assigns(:active_modules).map(&:id)).to include(my_module.id)
      expect(assigns(:navigator)).to include(id: experiment.code, archived: false)
    end

    it 'returns forbidden without canvas read permission' do
      allow(controller).to receive(:can_read_experiment_canvas?).and_return(false)
      get :canvas, params: { id: experiment.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET my_modules redirect targets' do
    it 'redirects to canvas by default' do
      get :my_modules, params: { id: experiment.id }
      expect(response).to redirect_to(canvas_experiment_path(experiment))
    end

    it 'redirects to module archive in archived canvas mode' do
      get :my_modules, params: { id: experiment.id, view_mode: 'archived' }
      expect(response).to redirect_to(module_archive_experiment_path(experiment))
    end
  end

  describe 'PUT view_type persists state' do
    it 'stores table view type and redirects to table' do
      put :view_type, params: { id: experiment.id, experiment: { view_type: 'table' } }
      expect(experiment.current_view_state(user).state['my_modules']['view_type']).to eq('table')
      expect(response).to redirect_to(experiment_my_modules_path(experiment_id: experiment))
    end
  end

  describe 'POST create (extra cases)' do
    it 'creates experiment and returns path' do
      expect do
        post :create, params: { project_id: project.id, experiment: { name: 'Created exp' } }, format: :json
      end.to change { project.experiments.count }.by(1)
      expect(JSON.parse(response.body)['path']).to include('/experiments/')
    end

    it 'returns unprocessable entity for invalid name' do
      expect do
        post :create, params: { project_id: project.id, experiment: { name: '' } }, format: :json
      end.not_to(change { Experiment.count })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key('name')
    end

    it 'returns forbidden without create permission' do
      allow(controller).to receive(:can_create_project_experiments?).and_return(false)
      expect do
        post :create, params: { project_id: project.id, experiment: { name: 'Created exp' } }, format: :json
      end.not_to(change { Experiment.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT update (extra cases)' do
    let(:action) { put :update, params: { id: experiment.id, experiment: experiment_params }, format: :json }

    def activity_count(type)
      Activity.where(type_of: Activity.type_ofs[type]).count
    end

    context 'when setting start date' do
      let(:experiment_params) { { start_date: '2024-01-10' } }

      it 'logs set start date activity' do
        expect { action }.to change { activity_count(:set_experiment_start_date) }.by(1)
        expect(experiment.reload.start_date.to_s).to eq('2024-01-10')
      end
    end

    context 'when changing start date' do
      let(:experiment_params) { { start_date: '2024-01-12' } }

      before { experiment.update_column(:start_date, Date.new(2024, 1, 1)) }

      it 'logs change start date activity' do
        expect { action }.to change { activity_count(:change_experiment_start_date) }.by(1)
      end
    end

    context 'when removing start date' do
      let(:experiment_params) { { start_date: '' } }

      before { experiment.update_column(:start_date, Date.new(2024, 1, 1)) }

      it 'logs remove start date activity' do
        expect { action }.to change { activity_count(:remove_experiment_start_date) }.by(1)
        expect(experiment.reload.start_date).to be_nil
      end
    end

    context 'when setting due date' do
      let(:experiment_params) { { due_date: '2024-02-10' } }

      it 'logs set due date activity' do
        expect { action }.to change { activity_count(:set_experiment_due_date) }.by(1)
        expect(experiment.reload.due_date.to_s).to eq('2024-02-10')
      end
    end

    context 'when changing due date' do
      let(:experiment_params) { { due_date: '2024-02-12' } }

      before { experiment.update_column(:due_date, Date.new(2024, 2, 1)) }

      it 'logs change due date activity' do
        expect { action }.to change { activity_count(:change_experiment_due_date) }.by(1)
      end
    end

    context 'when removing due date' do
      let(:experiment_params) { { due_date: '' } }

      before { experiment.update_column(:due_date, Date.new(2024, 2, 1)) }

      it 'logs remove due date activity' do
        expect { action }.to change { activity_count(:remove_experiment_due_date) }.by(1)
      end
    end

    context 'when changing status' do
      let(:experiment_params) { { status: 'in_progress' } }

      it 'logs change status activity with old and new status' do
        expect { action }.to change { activity_count(:change_experiment_status) }.by(1)
        expect(experiment.reload.status).to eq(:in_progress)
        activity = Activity.where(type_of: Activity.type_ofs[:change_experiment_status]).last
        expect(activity.values['message_items'].keys).to include('old_status', 'status')
      end
    end

    context 'when name is invalid' do
      let(:experiment_params) { { name: 'a' * 300 } }

      it 'returns unprocessable entity' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to have_key('name')
      end
    end

    context 'without manage permission' do
      let(:experiment_params) { { name: 'Forbidden name' } }

      it 'returns forbidden' do
        allow(controller).to receive(:can_manage_experiment?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
        expect(experiment.reload.name).not_to eq('Forbidden name')
      end
    end

    context 'when restoring without restore permission' do
      let(:experiment_params) { { archived: 'false' } }

      it 'returns forbidden' do
        allow(controller).to receive(:can_restore_experiment?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST archive (extra cases)' do
    it 'archives experiment and redirects to project' do
      post :archive, params: { id: experiment.id }
      expect(experiment.reload.archived?).to eq(true)
      expect(response).to redirect_to(project_path(project))
    end

    it 'redirects back with alert when save fails' do
      allow_any_instance_of(Experiment).to receive(:save).and_return(false)
      post :archive, params: { id: experiment.id }
      expect(flash[:alert]).to be_present
      expect(response).to have_http_status(:found)
    end

    it 'returns forbidden without archive permission' do
      allow(controller).to receive(:can_archive_experiment?).and_return(false)
      post :archive, params: { id: experiment.id }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(experiment.reload.archived?).to eq(false)
    end
  end

  describe 'POST archive_group / restore_group failures' do
    it 'does not archive when archiving raises' do
      allow_any_instance_of(Experiment).to receive(:archive!).and_raise(StandardError, 'fail')
      post :archive_group, params: { project_id: project.id, experiment_ids: [experiment.id] }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(experiment.reload.archived?).to eq(false)
    end

    it 'does not restore when restoring raises' do
      allow_any_instance_of(Experiment).to receive(:restore!).and_raise(StandardError, 'fail')
      post :restore_group, params: { project_id: project.id, experiment_ids: [archived_experiment.id] }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(archived_experiment.reload.archived?).to eq(true)
    end

    it 'returns forbidden without project read permission' do
      allow(controller).to receive(:can_read_project?).and_return(false)
      post :archive_group, params: { project_id: project.id, experiment_ids: [experiment.id] }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET projects_to_move (with target)' do
    let!(:target_project) { create :project, team: team, created_by: user, name: 'Target move project' }

    it 'lists other projects as targets' do
      get :projects_to_move, params: { id: experiment.id, query: 'Target' }, format: :json
      expect(JSON.parse(response.body)['data']).to include([target_project.id, target_project.name])
    end
  end

  describe 'POST clone (extra cases)' do
    let!(:project_second) { create(:project, team: team, created_by: user) }
    let(:action) { post :clone, params: { id: experiment.id, experiment: { project_id: project_second.id } } }

    it 'returns the cloned experiment url and creates the experiment' do
      expect { action }.to change { project_second.experiments.count }.by(1)
      expect(JSON.parse(response.body)['url']).to be_present
    end

    it 'returns unprocessable entity when service fails' do
      allow(Experiments::CopyExperimentAsTemplateService)
        .to receive(:call).and_return(double(succeed?: false, errors: {}))
      action
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['message']).to be_present
    end

    it 'returns forbidden without clone permission' do
      allow(controller).to receive(:can_clone_experiment?).and_return(false)
      expect { action }.not_to(change { Experiment.count })
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns forbidden without create permission in target project' do
      allow(controller).to receive(:can_create_project_experiments?).and_return(false)
      action
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST move (extra cases)' do
    let(:project_second) { create(:project, team: team, created_by: user) }

    it 'moves the experiment to another project' do
      post :move, params: { project_id: project_second.id, ids: [experiment.id] }
      expect(experiment.reload.project_id).to eq(project_second.id)
      expect(JSON.parse(response.body)['path']).to eq(project_experiments_path(project_second))
    end

    it 'returns forbidden without move permission' do
      allow(controller).to receive(:can_move_experiment?).and_return(false)
      post :move, params: { project_id: project_second.id, ids: [experiment.id] }
      expect(response).to have_http_status(:forbidden)
      expect(experiment.reload.project_id).to eq(project.id)
    end
  end

  describe 'GET move_modules_modal' do
    let!(:experiment_second) { create(:experiment, project: project, created_by: user) }

    it 'returns html and lists other manageable experiments' do
      get :move_modules_modal, params: { id: experiment.id }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('html')
      expect(assigns(:experiments)).to include(experiment_second)
      expect(assigns(:experiments)).not_to include(experiment)
    end
  end

  describe 'POST move_modules (extra cases)' do
    let!(:experiment_second) { create(:experiment, project: project, created_by: user) }

    it 'moves the task into the destination experiment' do
      post :move_modules, params: { id: experiment.id, to_experiment_id: experiment_second.id,
                                    my_module_ids: [my_module.id] }
      expect(my_module.reload.experiment_id).to eq(experiment_second.id)
    end

    it 'moves tasks to an older experiment (reverse lock order)' do
      source = create(:experiment, project: project, created_by: user)
      source_module = create(:my_module, experiment: source, created_by: user)
      post :move_modules, params: { id: source.id, to_experiment_id: experiment.id, my_module_ids: [source_module.id] }
      expect(response).to have_http_status(:success)
      expect(source_module.reload.experiment_id).to eq(experiment.id)
    end

    it 'returns forbidden when destination is not manageable' do
      post :move_modules, params: { id: experiment.id, to_experiment_id: -1, my_module_ids: [my_module.id] }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns forbidden when task cannot be moved' do
      allow(controller).to receive(:can_move_my_module?).and_return(false)
      post :move_modules, params: { id: experiment.id, to_experiment_id: experiment_second.id,
                                    my_module_ids: [my_module.id] }
      expect(response).to have_http_status(:forbidden)
      expect(my_module.reload.experiment_id).to eq(experiment.id)
    end

    it 'returns unprocessable entity for unknown task ids' do
      # RecordNotFound is caught by the inner StandardError rescue, so the outer 404 handler is unreachable.
      post :move_modules, params: { id: experiment.id, to_experiment_id: experiment_second.id, my_module_ids: [-1] }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['message']).to be_present
    end
  end

  describe 'GET module_archive (extra)' do
    let!(:archived_task) { create :my_module, :archived, experiment: experiment, created_by: user }

    it 'lists archived tasks and marks navigator as archived' do
      get :module_archive, params: { id: experiment.id }
      expect(assigns(:my_modules).map(&:id)).to include(archived_task.id)
      expect(assigns(:my_modules).map(&:id)).not_to include(my_module.id)
      expect(assigns(:navigator)[:archived]).to eq(true)
    end
  end

  describe 'GET fetch_workflow_img' do
    let(:attach_image) do
      lambda do |exp|
        exp.workflowimg.attach(io: File.open(Rails.root.join('spec/fixtures/files/test.jpg')),
                               filename: 'workflow.jpg', content_type: 'image/jpeg')
      end
    end

    it 'generates the image when missing and returns its url' do
      expect(Experiments::GenerateWorkflowImageService).to receive(:call) do |experiment:|
        attach_image.call(experiment)
      end
      get :fetch_workflow_img, params: { id: experiment.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['workflowimg_url']).to include('workflow.jpg')
    end

    it 'does not regenerate an existing image' do
      attach_image.call(experiment)
      expect(Experiments::GenerateWorkflowImageService).not_to receive(:call)
      get :fetch_workflow_img, params: { id: experiment.id }, format: :json
      expect(JSON.parse(response.body)['workflowimg_url']).to include('workflow.jpg')
    end
  end

  describe 'GET inventory_assigning_experiment_filter (extra)' do
    it 'returns experiments with assignable tasks' do
      get :inventory_assigning_experiment_filter, params: { project_id: project.id }, format: :json
      expect(JSON.parse(response.body)).to include([experiment.id, experiment.name])
    end

    it 'returns not found for unknown project' do
      get :inventory_assigning_experiment_filter, params: { project_id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET assigned_users_to_tasks' do
    it 'returns users designated to experiment tasks' do
      create :user_my_module, my_module: my_module, user: user
      get :assigned_users_to_tasks, params: { id: experiment.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).map { |u| u['value'] }).to eq([user.id])
    end

    it 'returns forbidden without read permission' do
      allow(controller).to receive(:can_read_experiment?).and_return(false)
      get :assigned_users_to_tasks, params: { id: experiment.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST archive_my_modules (extra cases)' do
    it 'archives the task' do
      post :archive_my_modules, params: { id: experiment.id, my_modules: [my_module.id] }
      expect(my_module.reload.archived?).to eq(true)
    end

    it 'reconnects neighbours of an archived task in the workflow' do
      first = create :my_module, experiment: experiment, created_by: user
      last = create :my_module, experiment: experiment, created_by: user
      create :connection, from: first, to: my_module
      create :connection, from: my_module, to: last
      post :archive_my_modules, params: { id: experiment.id, my_modules: [my_module.id] }
      expect(Connection.exists?(output_id: first.id, input_id: last.id)).to eq(true)
    end

    it 'returns unprocessable entity when archiving fails' do
      allow_any_instance_of(MyModule).to receive(:archive!).and_raise(StandardError, 'fail')
      post :archive_my_modules, params: { id: experiment.id, my_modules: [my_module.id] }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(my_module.reload.archived?).to eq(false)
    end

    it 'returns unprocessable entity without archive permission' do
      allow(controller).to receive(:can_archive_my_module?).and_return(false)
      post :archive_my_modules, params: { id: experiment.id, my_modules: [my_module.id] }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST batch_clone_my_modules (extra cases)' do
    let(:action) { post :batch_clone_my_modules, params: { id: experiment.id, my_module_ids: [my_module.id] } }

    it 'creates a clone and enqueues content copy' do
      expect(MyModules::CopyContentJob).to receive(:perform_later).with(user.id, my_module.id, anything)
      expect { action }.to change { experiment.my_modules.count }.by(1)
      expect(JSON.parse(response.body)['provisioning_status_urls'].size).to eq(1)
    end

    it 'returns unprocessable entity for invalid content' do
      allow_any_instance_of(MyModule).to receive(:raise_if_invalid_content!)
        .and_raise(MyModule::InvalidContentError, 'invalid content')
      expect { action }.not_to(change { MyModule.count })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq('invalid content')
    end

    it 'returns forbidden without manage permission' do
      allow(controller).to receive(:can_manage_experiment?).and_return(false)
      expect { action }.not_to(change { MyModule.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST actions_toolbar' do
    it 'returns available actions for selected experiments' do
      post :actions_toolbar, params: { items: [{ id: experiment.id }].to_json }, format: :json
      expect(response).to have_http_status(:success)
      names = JSON.parse(response.body)['actions'].map { |a| a['name'] }
      expect(names).to include('edit', 'archive')
    end
  end
end
