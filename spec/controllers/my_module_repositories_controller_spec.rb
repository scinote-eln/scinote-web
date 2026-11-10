# frozen_string_literal: true

require 'rails_helper'

describe MyModuleRepositoriesController, type: :controller do
  login_user
  include_context 'reference_project_structure'
  let!(:repository) { create :repository, created_by: user, team: team }
  let!(:repository_row) do
    create :repository_row, created_by: user, repository: repository
  end
  let!(:repository_row_2) do
    create :repository_row, created_by: user, repository: repository
  end

  describe 'PUT update (assign repository records)' do
    let(:params) do
      { my_module_id: my_module.id,
        id: repository.id,
        rows_to_assign: [repository_row.id],
        downstream: false }
    end
    let(:action) do
      put :update, params: params, format: :json
    end

    it 'calls create activity for assign_repository_record' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :assign_repository_record)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update (assign repository records downstream)' do
    it 'adds activity id DB' do
      parent_my_module = my_module
      params_downstream = { my_module_id: parent_my_module.id,
                            id: repository.id,
                            rows_to_assign: [repository_row.id],
                            downstream: true }
      3.times do |_i|
        child_module = create :my_module, experiment: experiment, created_by: experiment.created_by
        Connection.create(output_id: parent_my_module.id, input_id: child_module.id)
      end
      expect { put :update, params: params_downstream, format: :json }
        .to change { Activity.count }.by(4)
    end
  end

  describe 'PUT update (unassign repository records)' do
    let!(:mm_repository_row) do
      create :mm_repository_row, repository_row: repository_row,
                                 my_module: my_module,
                                 assigned_by: user
    end
    let(:params) do
      { my_module_id: my_module.id,
        id: repository.id,
        rows_to_unassign: [repository_row.id],
        downstream: false }
    end
    let(:action) do
      put :update, params: params, format: :json
    end

    it 'calls create activity for unassign_repository_record' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :unassign_repository_record)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update (unassign repository records downstream)' do
    it 'adds activity id DB' do
      parent_my_module = my_module
      create :mm_repository_row, repository_row: repository_row,
                                 my_module: parent_my_module,
                                 assigned_by: user
      params_downstream = { my_module_id: parent_my_module.id,
                            id: repository.id,
                            rows_to_unassign: [repository_row.id],
                            downstream: true }
      3.times do |_i|
        child_module = create :my_module, experiment: experiment, created_by: experiment.created_by
        Connection.create(output_id: parent_my_module.id, input_id: child_module.id)
        create :mm_repository_row, repository_row: repository_row,
                                   my_module: child_module,
                                   assigned_by: user
      end
      put :update, params: params_downstream, format: :json
      expect(Activity.count).to eq 4
    end
  end

  describe 'PUT update (assign and unassign repository records)' do
    let!(:mm_repository_row) do
      create :mm_repository_row, repository_row: repository_row_2,
                                 my_module: my_module,
                                 assigned_by: user
    end
    let(:params) do
      { my_module_id: my_module.id,
        id: repository.id,
        rows_to_assign: [repository_row.id],
        rows_to_unassign: [repository_row_2.id],
        downstream: false }
    end
    let(:action) do
      put :update, params: params, format: :json
    end

    it 'calls create activity for assign_repository_record and unassign_repository_record' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :assign_repository_record)))
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :unassign_repository_record)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update (assign and unassign repository records downstream)' do
    it 'adds activity id DB' do
      parent_my_module = my_module
      create :mm_repository_row, repository_row: repository_row_2,
                                 my_module: parent_my_module,
                                 assigned_by: user
      params_downstream = { my_module_id: parent_my_module.id,
                            id: repository.id,
                            rows_to_assign: [repository_row.id],
                            rows_to_unassign: [repository_row_2.id],
                            downstream: true }
      3.times do |_i|
        child_module = create :my_module, experiment: experiment, created_by: experiment.created_by
        Connection.create(output_id: parent_my_module.id, input_id: child_module.id)
        create :mm_repository_row, repository_row: repository_row_2,
                                   my_module: child_module,
                                   assigned_by: user
      end
      put :update, params: params_downstream, format: :json
      expect(Activity.count).to eq 8
    end
  end

  describe 'extra coverage' do
    render_views

    let(:base) { { my_module_id: my_module.id, id: repository.id } }

    def make_viewer
      UserAssignment.where(user: user, assignable: [project, experiment, my_module]).update_all(user_role_id: viewer_role.id)
    end

    def json
      JSON.parse(response.body)
    end

    describe 'unknown ids' do
      it 'raises for an unknown module' do
        # bug: app/controllers/my_module_repositories_controller.rb:376 keeps going after render_404
        # and dereferences nil (NoMethodError) instead of just returning 404
        expect do
          get :show, params: { my_module_id: -1, id: repository.id }, format: :json
        end.to raise_error(NoMethodError)
      end

      it 'returns 404 for an unknown repository' do
        get :show, params: { my_module_id: my_module.id, id: -1 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET show' do
      it 'renders the assigned repository with counts' do
        create :mm_repository_row, repository_row: repository_row, my_module: my_module, assigned_by: user
        get :show, params: base, format: :json
        expect(response).to have_http_status(:ok)
        expect(json.dig('data', 'id').to_i).to eq repository.id
      end
    end

    describe 'GET index_ag / unassigned_rows' do
      before { create :mm_repository_row, repository_row: repository_row, my_module: my_module, assigned_by: user }

      it 'lists assigned rows' do
        get :index_ag, params: base.merge(per_page: 10, page: 1), format: :json
        expect(response).to have_http_status(:ok)
        expect(json['meta']['total_count']).to eq 1
        expect(json['data'].size).to eq 1
      end

      it 'lists unassigned rows' do
        get :unassigned_rows, params: base.merge(per_page: 10, page: 1), format: :json
        expect(response).to have_http_status(:ok)
        expect(json['meta']['total_count']).to eq 1
        expect(json['data'].first['id'].to_i).to eq repository_row_2.id
      end

      it 'index_ag is forbidden when the module is not readable' do
        UserAssignment.where(user: user, assignable: [project, experiment, my_module]).destroy_all
        get :index_ag, params: base.merge(per_page: 10, page: 1), format: :json
        expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
      end
    end

    describe 'POST create (direct assign)' do
      it 'assigns the row and logs activity' do
        expect do
          post :create, params: { my_module_id: my_module.id, repository_row_id: repository_row.id }, format: :json
        end.to change { my_module.my_module_repository_rows.count }.by(1)
        expect(response).to have_http_status(:ok)
        expect(Activity.last.type_of).to eq 'assign_repository_record'
      end

      it 'returns 400 when the row is already assigned' do
        create :mm_repository_row, repository_row: repository_row, my_module: my_module, assigned_by: user
        post :create, params: { my_module_id: my_module.id, repository_row_id: repository_row.id }, format: :json
        expect(response).to have_http_status(:bad_request)
      end

      it 'is forbidden for a viewer' do
        make_viewer
        expect do
          post :create, params: { my_module_id: my_module.id, repository_row_id: repository_row.id }, format: :json
        end.not_to(change { MyModuleRepositoryRow.count })
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PUT update failure and permissions' do
      it 'is forbidden for a viewer' do
        make_viewer
        put :update, params: base.merge(rows_to_assign: [repository_row.id]), format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 400 when the service fails' do
        allow(RepositoryRows::MyModuleAssignUnassignService).to receive(:call)
          .and_return(double(succeed?: false, assigned_rows_count: 0, unassigned_rows_count: 0))
        put :update, params: base.merge(rows_to_assign: [repository_row.id]), format: :json
        expect(response).to have_http_status(:bad_request)
        expect(json['repository_id']).to eq repository.id
      end

      it 'assigns the rows' do
        expect do
          put :update, params: base.merge(rows_to_assign: [repository_row.id]), format: :json
        end.to change { my_module.my_module_repository_rows.count }.by(1)
        expect(json['assigned_count']).to eq 1
      end
    end

    describe 'POST batch_destroy' do
      before { create :mm_repository_row, repository_row: repository_row, my_module: my_module, assigned_by: user }

      it 'unassigns rows' do
        expect do
          post :batch_destroy, params: base.merge(rows_to_unassign: [repository_row.id]), format: :json
        end.to change { my_module.my_module_repository_rows.count }.by(-1)
        expect(response).to have_http_status(:ok)
      end

      it 'returns 400 when the service fails' do
        allow(RepositoryRows::MyModuleAssignUnassignService).to receive(:call)
          .and_return(double(succeed?: false, assigned_rows_count: 0, unassigned_rows_count: 0))
        post :batch_destroy, params: base.merge(rows_to_unassign: [repository_row.id]), format: :json
        expect(response).to have_http_status(:bad_request)
      end

      it 'is forbidden for a viewer' do
        make_viewer
        post :batch_destroy, params: base.merge(rows_to_unassign: [repository_row.id]), format: :json
        expect(response).to have_http_status(:forbidden)
        expect(my_module.my_module_repository_rows.count).to eq 1
      end
    end

    describe 'POST assign_my_modules' do
      it 'assigns rows to several modules' do
        other = create :my_module, experiment: experiment, created_by: user
        expect do
          post :assign_my_modules, params: { id: repository.id, my_module_ids: [my_module.id, other.id],
                                             rows_to_assign: [repository_row.id] }, format: :json
        end.to change { MyModuleRepositoryRow.count }.by(2)
        expect(json).to eq('assigned_count' => 2, 'skipped_count' => 0)
      end

      it 'rolls back and returns 422 on failure' do
        allow(RepositoryRows::MyModuleAssignUnassignService).to receive(:call)
          .and_return(double(succeed?: false))
        post :assign_my_modules, params: { id: repository.id, my_module_ids: [my_module.id],
                                           rows_to_assign: [repository_row.id] }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'is forbidden when a module cannot be assigned' do
        make_viewer
        post :assign_my_modules, params: { id: repository.id, my_module_ids: [my_module.id],
                                           rows_to_assign: [repository_row.id] }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'modals and lists' do
      it 'assign_repository_records_modal lists assignable downstream modules' do
        child = create :my_module, experiment: experiment, created_by: user
        Connection.create(output_id: my_module.id, input_id: child.id)
        get :assign_repository_records_modal, params: base, format: :json
        expect(json['my_modules']).to include(child.name)
      end

      # bug: the partials below do not exist in app/views, so these actions always raise
      # (my_modules/modals/_update_repository_records_modal_content, my_modules/repositories/_repositories_list,
      # my_modules/repositories/_full_view_table); controller lines 188, 233 and 244 are dead
      it 'update_repository_records_modal raises MissingTemplate' do
        expect do
          post :update_repository_records_modal, params: base.merge(selected_rows: [repository_row.id]), format: :json
        end.to raise_error(ActionView::MissingTemplate)
      end

      it 'repositories_list_html raises MissingTemplate' do
        expect do
          get :repositories_list_html, params: { my_module_id: my_module.id }, format: :json
        end.to raise_error(ActionView::MissingTemplate)
      end

      it 'repositories_list serializes assigned repositories' do
        create :mm_repository_row, repository_row: repository_row, my_module: my_module, assigned_by: user
        get :repositories_list, params: { my_module_id: my_module.id }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it 'repositories_dropdown_list returns readable repositories' do
        get :repositories_dropdown_list, params: { my_module_id: my_module.id }, format: :json
        expect(json['repositories'].map { |r| r['id'] }).to include(repository.id)
      end

      it 'full_view_table raises MissingTemplate' do
        expect do
          get :full_view_table, params: base.merge(include_stock_consumption: 'false'), format: :json
        end.to raise_error(ActionView::MissingTemplate)
      end
    end

    describe 'POST export_repository' do
      it 'enqueues an export and logs activity' do
        expect(RepositoryZipExportJob).to receive(:perform_later)
        expect do
          post :export_repository, params: base.merge(header_ids: [-3]), format: :json
        end.to change { Activity.where(type_of: :export_inventory_items_assigned_to_task).count }.by(1)
        expect(response).to have_http_status(:ok)
      end

      it 'returns 422 without header ids' do
        post :export_repository, params: base, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'toolbars' do
      it 'actions_toolbar returns actions' do
        post :actions_toolbar, params: { my_module_id: my_module.id, items: [{ id: repository_row.id }].to_json },
                               format: :json
        expect(json['actions']).to be_an(Array)
      end

      it 'unassigned_actions_toolbar returns actions' do
        post :unassigned_actions_toolbar, params: base.merge(items: [{ id: repository_row.id }].to_json),
                                          format: :json
        expect(json['actions']).to be_an(Array)
      end
    end

    describe 'stock consumption' do
      let!(:stock_cell) { create :repository_cell, :stock_value, repository_row: repository_row }

      before { allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(true) }
      let!(:mm_row) do
        create :mm_repository_row, repository_row: repository_row, my_module: my_module, assigned_by: user
      end

      it 'consume_modal renders json' do
        get :consume_modal, params: base.merge(row_id: repository_row.id), format: :json
        expect(response).to have_http_status(:ok)
      end

      it 'update_consumption consumes stock' do
        post :update_consumption, params: base.merge(module_row_id: mm_row.id, stock_consumption: 3, comment: 'used'),
                                  format: :json
        expect(response).to have_http_status(:ok)
        expect(mm_row.reload.stock_consumption).to eq 3
      end

      it 'update_consumption is forbidden for a viewer' do
        make_viewer
        post :update_consumption, params: base.merge(module_row_id: mm_row.id, stock_consumption: 3), format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
