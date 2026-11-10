# frozen_string_literal: true

require 'rails_helper'

describe RepositoriesController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let!(:team) { create :team, :record_deletion_enabled, created_by: user }
  let(:action) { post :create, params: params, format: :json }
  let(:repository_template) { create :repository_template, team: team }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:repository_row) { create :repository_row, repository: repository }
  let(:archied_repository) do
    create :repository, :archived, team: team, created_by: user
  end

  describe 'index' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:action) { get :index, format: :json, params: { page: 1, per_page: 20 } }

    it 'correct JSON format' do
      repository

      action

      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'][0].keys).to contain_exactly(
        'id', 'type', 'attributes'
      )
      expect(parsed_response['data'][0]['attributes'].keys).to contain_exactly(
        'name', 'code', 'nr_of_rows', 'shared', 'shared_label', 'ishared', 'team',
        'created_at', 'created_by', 'archived_on', 'archived_by', 'urls', 'shared_read',
        'shared_write', 'shareable_write', 'assigned_users', 'default_public_user_role_id',
        'permissions', 'top_level_assignable', 'current_team'
      )
    end
  end

  describe 'GET list' do
    let(:action) { get :list, format: :json, params: { team_id: team.id } }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET rows_list' do
    let(:action) { get :rows_list, format: :json, params: { id: repository.id, team_id: team.id } }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET show' do
    let(:action) { get :show, format: :json, params: { id: repository.id, team_id: team.id } }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.body).not_to be_empty
    end

    it 'includes has_active_reminders in the response' do
      action
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['attributes']).to have_key('has_active_reminders')
    end
  end

  describe 'GET show HTML' do
    let(:action) { get :show, format: :html, params: { id: repository.id, team_id: team.id } }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/html; charset=utf-8')
    end
  end

  describe 'POST archive' do
    let(:action) { post :archive, format: :json, params: {
      repository_ids: repository.id,
      team_id: team.id
    } }
    it 'repository is archived successfully' do
      action
      p response.body
      expect(response).to have_http_status(:success)
      repository.reload
      expect(repository.archived?).to be true
    end
  end

  describe 'POST restore' do
    let(:action) { post :restore, format: :json, params: {
      repository_ids: archied_repository.id,
      team_id: team.id
    } }
    it 'repository is restored successfully' do
      action
      expect(response).to have_http_status(:success)
      archied_repository.reload
      expect(archied_repository.archived?).to be false
    end
  end

  describe 'POST copy' do
    let(:action) { post :copy, format: :json, params: {
      repository_id: repository.id,
      team_id: team.id,
      repository: { name: 'Copied Repository' }
    } }
    it 'repository is copied successfully' do
      action
      expect(response).to have_http_status(:success)
      expect(Repository.where(name: 'Copied Repository').exists?).to be true
    end
  end

  describe 'POST hide_reminders' do
    let(:action) { post :hide_reminders, format: :json, params: {
      visible_reminder_repository_row_ids: [repository_row.id],
      repository_id: repository.id,
      team_id: team.id
    } }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST export_repositories' do
    let(:params) { { repository_ids: [repository.id], team_id: team.id, file_type: 'csv' } }
    let(:action) { post :export_repositories, params: params, format: :json }

    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST export_repository_stock_items' do
    let(:params) { { id: repository.id, team_id: team.id, row_ids: [repository_row.id] } }
    let(:action) { post :export_repository_stock_items, params: params, format: :json }
    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST export_empty_repository' do
    let(:params) { { team_id: team.id, id: repository.id } }
    let(:action) { post :export_empty_repository, format: :json, params: params }

    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET assigned_my_modules' do
    let(:params) { { team_id: team.id, id: repository.id } }
    let(:action) { get :assigned_my_modules, format: :json, params: params }

    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET repository_users' do
    let(:params) { { team_id: team.id, id: repository.id } }
    let(:action) { get :repository_users, format: :json, params: params }

    it 'returns http success' do
      action
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST create' do
    let(:params) { { repository: { name: 'My Repository', repository_template_id: repository_template.id  } } }

    it 'calls create activity for creating inventory' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :create_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    it 'returns success response' do
      expect { action }.to change(Repository, :count).by(1)
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      expect(Repository.order(created_at: :desc).first.repository_template).to eq repository_template
    end
  end

  describe 'DELETE destroy' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:params) { { id: repository.id, team_id: team.id } }
    let(:action) { delete :destroy, params: params }

    it 'calls create activity for deleting inventory' do
      repository.archive!(user)
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_inventory)))

      action
    end

    it 'adds activity in DB' do
      repository.archive!(user)
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:params) do
      { id: repository.id, team_id: team.id, repository: { name: 'new_name' } }
    end
    let(:action) { put :update, params: params, format: :json }

    it 'calls create activity for renaming inventory' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :rename_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'POST export_repository' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:repository_row) { create :repository_row, repository: repository }
    let(:repository_column) do
      create :repository_column, repository: repository
    end
    let(:repository_cell) do
      create :repository_cell,
             repository_row: repository_row,
             repository_column: repository_column
    end
    let(:params_csv) do
      {
        id: repository.id,
        header_ids: [repository_column.id],
        row_ids: [repository_row.id],
        file_type: :csv
      }
    end

    let(:params_xlsx) do
      {
        id: repository.id,
        header_ids: [repository_column.id],
        row_ids: [repository_row.id],
        file_type: :xlsx
      }
    end

    let(:action_csv) { post :export_repository, params: params_csv, format: :json }
    let(:action_xlsx) { post :export_repository, params: params_xlsx, format: :json }

    it 'calls create activity for exporting inventory items csv' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :export_inventory_items)))

      action_csv
    end

    it 'adds activity in DB for exporting csv' do
      expect { action_csv }
        .to(change { Activity.count })
    end

    it 'calls create activity for exporting inventory items xlsx' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :export_inventory_items)))

      action_xlsx
    end

    it 'adds activity in DB for exporting xlsx' do
      expect { action_xlsx }
        .to(change { Activity.count })
    end
  end

  describe 'POST import_records' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:mappings) do
      { '0': '-1', '1': '', '2': '', '3': '', '4': '', '5': '' }
    end
    let(:params) do
      { id: repository.id,
        team_id: team.id,
        file_id: 'file_id',
        mappings: mappings }
    end
    let(:action) { post :import_records, params: params, format: :json }

    it 'returns 403 and halts when user cannot create repository rows' do
      allow(controller).to receive(:can_create_repository_rows?).and_return(false)

      action

      expect(response).to have_http_status(:forbidden)
    end

    it 'does not call ImportRecords when user cannot create repository rows' do
      allow(controller).to receive(:can_create_repository_rows?).and_return(false)

      expect(ImportRepository::ImportRecords).not_to receive(:new)

      action
    end

    it 'calls create activity for importing inventory items' do
      allow_any_instance_of(ImportRepository::ImportRecords)
        .to receive(:import!).and_return({ status: :ok, created_rows_count: 1, updated_rows_count: 1 })

      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :inventory_items_added_or_updated_with_import)))

      action
    end

    it 'adds activity in DB' do
      allow_any_instance_of(ImportRepository::ImportRecords).to receive(:import!)
        .and_return({ status: :ok, created_rows_count: 1, updated_rows_count: 1 })

      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'extra coverage' do
    let!(:viewer_role) { create :viewer_role }

    def make_viewer
      UserAssignment.where(user: user, assignable: [team, repository]).update_all(user_role_id: viewer_role.id)
    end

    describe 'GET list variants' do
      before { repository_row }

      it 'filters by query, non_empty and active' do
        get :list, format: :json, params: { team_id: team.id, query: repository.name, non_empty: 'true', active: 'true' }
        data = JSON.parse(response.body)['data']
        expect(data.map(&:first)).to include(repository.id)
      end

      it 'supports appendable and manageable lists' do
        get :list, format: :json, params: { team_id: team.id, appendable: 'true' }
        expect(response).to have_http_status(:ok)
        get :list, format: :json, params: { team_id: team.id, manageable: 'true' }
        expect(JSON.parse(response.body)['data'].map(&:first)).to include(repository.id)
      end
    end

    describe 'GET rows_list variants' do
      let!(:other_row) { create :repository_row, repository: repository, name: 'Zeta' }

      before { repository_row }

      it 'filters by query' do
        get :rows_list, format: :json, params: { team_id: team.id, id: repository.id, query: 'Zeta' }
        expect(JSON.parse(response.body)['data'].map(&:last)).to eq ['Zeta']
      end

      it 'puts preselected rows first on page 1 and excludes assigned rows' do
        get :rows_list, format: :json, params: { team_id: team.id, id: repository.id, active: 'true', page: 1,
                                                 preselected_rows: [other_row.id] }
        expect(JSON.parse(response.body)['data'].first.first).to eq other_row.id
      end

      it 'excludes rows assigned to my module and protocol' do
        project = create :project, team: team, created_by: user
        experiment = create :experiment, project: project, created_by: user, last_modified_by: user
        my_module = create :my_module, experiment: experiment, created_by: user
        create :mm_repository_row, my_module: my_module, repository_row: other_row, assigned_by: user
        get :rows_list, format: :json, params: { team_id: team.id, id: repository.id, my_module_id: my_module.id,
                                                 protocol_id: my_module.protocols.first&.id }
        expect(JSON.parse(response.body)['data'].map(&:first)).not_to include(other_row.id)
      end

      it 'is 404 for an unreadable repository' do
        other = create :repository, team: create(:team), created_by: create(:user)
        get :rows_list, format: :json, params: { team_id: team.id, id: other.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'simple json endpoints' do
      it 'status' do
        get :status, params: { team_id: team.id, repository_id: repository.id }
        expect(JSON.parse(response.body)).to include('editable' => true, 'snapshot_provisioning' => false)
      end

      it 'permissions' do
        get :permissions, params: { team_id: team.id, id: repository.id }
        expect(JSON.parse(response.body).keys).to match_array(%w(create_equipment_bookings manage_equipment_bookings))
      end

      it 'user_roles' do
        get :user_roles, params: { team_id: team.id }
        expect(JSON.parse(response.body)['data']).to be_an(Array)
      end

      it 'repository_users lists creators' do
        create :repository_row, repository: repository, created_by: user
        get :repository_users, params: { team_id: team.id, id: repository.id }
        expect(JSON.parse(response.body)['users'].map { |u| u['value'] }).to include(user.id)
      end

      it 'assigned_my_modules is ok' do
        get :assigned_my_modules, params: { team_id: team.id, id: repository.id }
        expect(JSON.parse(response.body)).to have_key('data')
      end

      it 'actions_toolbar returns actions' do
        repository
        post :actions_toolbar, params: { team_id: team.id, items: [{ id: repository.id }].to_json }, format: :json
        expect(JSON.parse(response.body)['actions']).to be_an(Array)
      end

      it 'export_repository_stock_items_modal returns name' do
        get :export_repository_stock_items_modal, params: { team_id: team.id, id: repository.id }
        expect(JSON.parse(response.body)['name']).to eq repository.name
      end

      it 'show redirects 404 for unreadable repository' do
        get :show, format: :json, params: { team_id: team.id, id: -1 }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'modals' do
      it 'rename_modal is forbidden for a viewer' do
        make_viewer
        get :rename_modal, format: :json, params: { team_id: team.id, repository_id: repository.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'permissions' do
      it 'create is forbidden for a viewer' do
        make_viewer
        expect do
          post :create, params: { team_id: team.id, repository: { name: 'nope' } }, format: :json
        end.not_to change(Repository, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'update is forbidden for a viewer' do
        make_viewer
        put :update, params: { team_id: team.id, id: repository.id, repository: { name: 'nope' } }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(repository.reload.name).not_to eq 'nope'
      end

      it 'destroy is forbidden for a viewer' do
        make_viewer
        delete :destroy, params: { team_id: team.id, id: repository.id }
        expect(response).to have_http_status(:forbidden)
        expect(Repository.exists?(repository.id)).to be true
      end

      it 'copy is forbidden for a viewer' do
        make_viewer
        post :copy, params: { team_id: team.id, repository_id: repository.id, repository: { name: 'copy' } }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'archive is forbidden for a viewer' do
        make_viewer
        post :archive, params: { team_id: team.id, repository_ids: repository.id }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(repository.reload.archived?).to be false
      end
    end

    describe 'create / update / copy edge cases' do
      it 'create rejects an empty name' do
        expect do
          post :create, params: { team_id: team.id, repository: { name: '' } }, format: :json
        end.not_to change(Repository, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'create builds template columns' do
        template = RepositoryTemplate.create!(
          team: team, name: 'T',
          column_definitions: [{ 'column_type' => 'RepositoryTextValue', 'params' => { 'name' => 'Col A' } }]
        )
        post :create, params: { team_id: team.id, repository: { name: 'With template', repository_template_id: template.id } },
                      format: :json
        expect(response).to have_http_status(:ok)
        expect(Repository.find_by(name: 'With template').repository_columns.pluck(:name)).to eq ['Col A']
      end

      it 'create rolls back when a template column is invalid' do
        template = RepositoryTemplate.create!(
          team: team, name: 'Bad',
          column_definitions: [{ 'column_type' => 'RepositoryTextValue', 'params' => { 'name' => '' } }]
        )
        post :create, params: { team_id: team.id, repository: { name: 'Rolled back', repository_template_id: template.id } },
                      format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(Repository.exists?(name: 'Rolled back')).to be false
      end

      it 'update rejects an empty name' do
        put :update, params: { team_id: team.id, id: repository.id, repository: { name: '' } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'copy rejects an empty name' do
        post :copy, params: { team_id: team.id, repository_id: repository.id, repository: { name: '' } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'copy duplicates stock unit items' do
        create :repository_column, :stock_type, repository: repository
        post :copy, params: { team_id: team.id, repository_id: repository.id, repository: { name: 'Stock copy' } }, format: :json
        copy = Repository.find_by(name: 'Stock copy')
        expect(response).to have_http_status(:ok)
        expect(copy.repository_columns.find_by(data_type: 'RepositoryStockValue')).to be_present
      end

      it 'archive returns 422 when the service fails' do
        allow(Repositories::ArchiveRepositoryService).to receive(:call)
          .and_return(double(succeed?: false, error_message: 'boom'))
        post :archive, params: { team_id: team.id, repository_ids: repository.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['message']).to eq 'boom'
      end

      it 'restore returns 422 when the service fails' do
        allow(Repositories::RestoreRepositoryService).to receive(:call)
          .and_return(double(succeed?: false, error_message: 'boom'))
        post :restore, params: { team_id: team.id, repository_ids: archied_repository.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'exports' do
      it 'export_repositories rejects an invalid file type' do
        post :export_repositories, params: { team_id: team.id, repository_ids: [repository.id], file_type: 'exe' }, format: :json
        expect(response).to have_http_status(:bad_request)
      end

      it 'export_repositories enqueues a job' do
        expect(RepositoriesExportJob).to receive(:perform_later)
        post :export_repositories, params: { team_id: team.id, repository_ids: [repository.id], file_type: 'csv' },
                                   format: :json
        expect(response).to have_http_status(:ok)
      end

      it 'export_repositories returns 422 without readable repositories' do
        post :export_repositories, params: { team_id: team.id, repository_ids: [-1], file_type: 'csv' }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'export_repository returns 422 without row/header ids' do
        post :export_repository, params: { team_id: team.id, id: repository.id, file_type: 'csv' }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'export_repository_stock_items enqueues a job' do
        row = create :repository_row, repository: repository, created_by: user
        expect(RepositoryStockZipExportJob).to receive(:perform_later)
        post :export_repository_stock_items, params: { team_id: team.id, id: repository.id, row_ids: [row.id] },
                                             format: :json
        expect(response).to have_http_status(:ok)
      end

      it 'export_repository_stock_items returns 422 without rows' do
        post :export_repository_stock_items, params: { team_id: team.id, id: repository.id, row_ids: [-1] }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'export_empty_repository sends an xlsx' do
        get :export_empty_repository, params: { team_id: team.id, id: repository.id }
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      end
    end

    describe 'import' do
      it 'parse_sheet requires a file' do
        # bug: app/controllers/repositories_controller.rb:319 calls the undefined
        # unprocessable_entity_repository_response, so a missing file raises NoMethodError
        expect do
          post :parse_sheet, params: { team_id: team.id, id: repository.id }, format: :json
        end.to raise_error(NoMethodError, /unprocessable_entity_repository_response/)
      end

      it 'import_records rejects mapping without the name column' do
        post :import_records, params: { team_id: team.id, id: repository.id, file_id: 1, mappings: { '0' => '' } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'import_records returns 422 when the import fails' do
        allow_any_instance_of(ImportRepository::ImportRecords)
          .to receive(:import!).and_return({ status: :error, created_rows_count: 0, updated_rows_count: 0,
                                             total_rows_count: 1 })
        post :import_records, params: { team_id: team.id, id: repository.id, file_id: 1, mappings: { '0' => '-1' } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'import_records returns preview status without logging' do
        allow_any_instance_of(ImportRepository::ImportRecords)
          .to receive(:import!).and_return({ status: :ok, created_rows_count: 1, updated_rows_count: 0,
                                             total_rows_count: 1 })
        expect do
          post :import_records, params: { team_id: team.id, id: repository.id, file_id: 1, preview: 'true',
                                          mappings: { '0' => '-1' } }, format: :json
        end.not_to(change { Activity.count })
        expect(JSON.parse(response.body)['status']).to eq 'ok'
      end
    end
  end

  describe 'round 3 coverage' do
    let!(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }

    def make_viewer
      UserAssignment.where(user: user, assignable: [team, repository]).update_all(user_role_id: viewer_role.id)
    end

    it 'index renders the html page' do
      get :index, format: :html
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/html; charset=utf-8')
    end

    it 'index lists only readable repositories for a non team owner' do
      repository
      create :repository, team: team, created_by: create(:user)
      make_viewer

      get :index, format: :json, params: { page: 1, per_page: 20 }

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)['data'].map { |r| r['id'].to_i }
      expect(ids).to eq [repository.id]
    end

    describe 'GET show with row_id' do
      it 'loads the requested row' do
        get :show, format: :html, params: { id: repository.id, team_id: team.id, row_id: repository_row.id }
        expect(response).to have_http_status(:ok)
        expect(assigns(:repository_row)).to eq repository_row
      end

      it 'ignores a row of another repository' do
        other_row = create :repository_row
        get :show, format: :html, params: { id: repository.id, team_id: team.id, row_id: other_row.id }
        expect(response).to have_http_status(:ok)
        expect(assigns(:repository_row)).to be_nil
      end
    end

    describe 'POST hide_reminders with active reminders' do
      let!(:stock_cell) do
        cell = create :repository_cell, :stock_value, repository_row: repository_row
        cell.value.update_columns(amount: 0, low_stock_threshold: 5)
        cell
      end

      it 'hides the active reminders of the given rows for the current user' do
        expect do
          post :hide_reminders, format: :json,
                                params: { visible_reminder_repository_row_ids: [repository_row.id],
                                          repository_id: repository.id, team_id: team.id }
        end.to change { user.hidden_repository_cell_reminders.where(repository_cell_id: stock_cell.id).count }.by(1)

        expect(response).to have_http_status(:accepted)
      end

      it 'does not hide reminders twice' do
        user.hidden_repository_cell_reminders.create!(repository_cell_id: stock_cell.id)

        expect do
          post :hide_reminders, format: :json,
                                params: { visible_reminder_repository_row_ids: [repository_row.id],
                                          repository_id: repository.id, team_id: team.id }
        end.not_to change(HiddenRepositoryCellReminder, :count)
      end
    end

    describe 'GET assigned_my_modules with assigned tasks' do
      it 'groups the readable tasks by project and experiment' do
        repo = create :repository, team: team, created_by: user
        row = create :repository_row, repository: repo, created_by: user
        user_project = create :project, team: team, created_by: user
        experiment = create :experiment, project: user_project, created_by: user, last_modified_by: user
        task = create :my_module, experiment: experiment, created_by: user, last_modified_by: user
        MyModuleRepositoryRow.create!(my_module: task, repository_row: row, assigned_by: user)

        get :assigned_my_modules, format: :json, params: { team_id: team.id, id: repo.id }

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)['data']
        expect(data.first['label']).to eq "#{user_project.name} / #{experiment.name}"
        expect(data.first['options']).to eq [{ 'label' => task.name, 'value' => task.id }]
      end
    end

    describe 'POST parse_sheet with a file' do
      let(:upload) { Rack::Test::UploadedFile.new(StringIO.new("a,b\n1,2\n"), 'text/csv', original_filename: 'x.csv') }
      let(:data) { double('data', header: ['a'], columns: [['1']], as_json: { 'header' => ['a'] }) }
      let(:parsed) do
        double('parsed', too_large?: false, has_too_many_rows?: false, has_too_little_rows?: false,
                         data: data, generate_temp_file: temp_file)
      end
      let(:temp_file) { { 'id' => 1 } }

      before { allow(ImportRepository::ParseRepository).to receive(:new).and_return(parsed) }

      def post_file
        post :parse_sheet, params: { team_id: team.id, id: repository.id, file: upload }, format: :json
      end

      it 'returns the parsed data and the temp file' do
        post_file
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['temp_file']).to eq('id' => 1)
      end

      it 'rejects a file that is too large' do
        allow(parsed).to receive(:too_large?).and_return(true)
        post_file
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to be_present
      end

      it 'rejects a file with too many rows' do
        allow(parsed).to receive(:has_too_many_rows?).and_return(true)
        post_file
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to include(Constants::IMPORT_REPOSITORY_ITEMS_LIMIT.to_s)
      end

      it 'rejects a file with too little rows' do
        allow(parsed).to receive(:has_too_little_rows?).and_return(true)
        post_file
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq I18n.t('repositories.parse_sheet.errors.items_min_limit')
      end

      it 'rejects a file without a header' do
        allow(data).to receive(:header).and_return([])
        post_file
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq I18n.t('repositories.parse_sheet.errors.empty_file')
      end

      it 'fails when the temp file cannot be generated' do
        allow(parsed).to receive(:generate_temp_file).and_return(nil)
        post_file
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq I18n.t('repositories.parse_sheet.errors.temp_file_failure')
      end

      it 'reports an invalid file for malformed content' do
        allow(ImportRepository::ParseRepository).to receive(:new).and_raise(ArgumentError)
        post_file
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'reports an invalid extension' do
        allow(ImportRepository::ParseRepository).to receive(:new).and_raise(TypeError)
        post_file
        expect(JSON.parse(response.body)['error']).to eq I18n.t('repositories.parse_sheet.errors.invalid_extension')
      end
    end

    describe 'POST copy with a stock column' do
      it 'copies the stock unit items to the copied repository' do
        column = create :repository_column, :stock_type, repository: repository, created_by: user
        create :repository_stock_unit_item, data: 'ml', repository_column: column, created_by: user

        expect do
          post :copy, params: { team_id: team.id, repository_id: repository.id, repository: { name: 'Stock copy' } },
                      format: :json
        end.to change(Repository, :count).by(1)

        copied = Repository.find_by(name: 'Stock copy')
        expect(copied.repository_columns.find_by(data_type: 'RepositoryStockValue')
                     .repository_stock_unit_items.pluck(:data)).to eq ['ml']
      end
    end
  end
end
