# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRowsController, type: :controller do
  login_user
  render_views
  let!(:user) { controller.current_user }
  let!(:team) { create :team, :record_deletion_enabled, created_by: user }
  let!(:viewer_role) { create :viewer_role }
  let!(:repository) { create :repository, team: team, created_by: user }
  let!(:repository_state) do
    RepositoryTableState.create(
      repository: repository,
      user: user,
      state: repository.default_table_state
    )
  end
  let!(:repository_row) do
    create :repository_row, repository: repository,
                            created_by: user,
                            last_modified_by: user
  end

  let!(:user_two) { create :user, email: 'new@user.com' }
  let!(:team_two) { create :team, created_by: user_two }
  let!(:repository_two) do
    create :repository, team: team_two, created_by: user_two
  end
  let!(:repository_row_two) do
    create :repository_row, repository: repository_two,
                            created_by: user_two,
                            last_modified_by: user_two
  end

  describe '#show' do
    it 'unsuccessful response with non existing id' do
      get :show, format: :json, params: { repository_id: repository.id, id: -1 }
      expect(response).to have_http_status(:not_found)
    end

    it 'unsuccessful response with id from another repository' do
      get :show, format: :json, params: { repository_id: repository.id, id: repository_row_two.id }
      expect(response).to have_http_status(:not_found)
    end

    it 'successful response' do
      allow_any_instance_of(ActionView::Helpers::AssetUrlHelper).to receive(:asset_path)
      get :show, format: :json, params: { repository_id: repository.id, id: repository_row.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe '#index_ag' do
    before { repository.repository_rows.destroy_all }

    let!(:active_repository_row) do
      create :repository_row, repository: repository, created_by: user, last_modified_by: user, archived: false
    end
    let!(:archived_repository_row) do
      create :repository_row, repository: repository, created_by: user, last_modified_by: user, archived: true
    end

    it 'returns only active rows by default' do
      get :index_ag, params: { repository_id: repository.id, per_page: 20, page: 1 }, format: :json
      response_body = JSON.parse(response.body)
      ids = response_body['data'].map { |row| row['id'].to_i }

      expect(ids).to include(active_repository_row.id)
      expect(ids).not_to include(archived_repository_row.id)
    end

    it 'returns only archived rows when view_mode is archived' do
      get :index_ag, params: { repository_id: repository.id, per_page: 20, page: 1, view_mode: 'archived' }, format: :json
      response_body = JSON.parse(response.body)
      ids = response_body['data'].map { |row| row['id'].to_i }

      expect(ids).to include(archived_repository_row.id)
      expect(ids).not_to include(active_repository_row.id)
    end

    context 'when reminders are enabled' do
      # Repository.reminders_enabled? delegates to stock management
      before { allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(true) }

      let!(:date_column) do
        create :repository_column, :date_type, repository: repository,
                                               created_by: user,
                                               metadata: { 'reminder_value' => '5',
                                                           'reminder_unit' => '86400',
                                                           'reminder_message' => 'Check expiry' }
      end
      let!(:date_value) do
        create :repository_date_value, data: Date.current + 2.days,
                                       repository_cell_attributes: { repository_row: active_repository_row,
                                                                     repository_column: date_column }
      end

      it 'flags the reminder of a date cell inside the reminder window' do
        get :index_ag, params: { repository_id: repository.id, per_page: 20, page: 1 }, format: :json
        response_body = JSON.parse(response.body)
        row = response_body['data'].find { |r| r['id'].to_i == active_repository_row.id }

        expect(row.dig('attributes', "col_#{date_column.id}", 'value', 'reminder')).to be(true)
      end
    end
  end

  describe 'POST #copy_records' do
    it 'returns a success response' do
      post :copy_records, params: { repository_id: repository.id,
                                    selected_rows: [repository_row.id] }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { repository_id: repository.id, repository_row: { name: 'row_name' } }
    end

    it 'calls create activity for creating inventory item' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :create_item_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      {
        repository_id: repository.id,
        id: repository_row.id,
        repository_row: { name: 'row_name' }
      }
    end

    it 'calls create activity for editing intentory item' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :edit_item_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    context 'when reminders are enabled' do
      # Repository.reminders_enabled? delegates to stock management
      before { allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(true) }

      let!(:date_column) do
        create :repository_column, :date_type, repository: repository,
                                               created_by: user,
                                               metadata: { 'reminder_value' => '5',
                                                           'reminder_unit' => '86400',
                                                           'reminder_message' => 'Check expiry' }
      end
      let!(:date_value) do
        create :repository_date_value, data: date,
                                       repository_cell_attributes: { repository_row: repository_row,
                                                                     repository_column: date_column }
      end
      let(:active_reminders_count) { JSON.parse(response.body).dig('data', 'attributes', 'active_reminders_count') }

      context 'when the row has an active date reminder' do
        let(:date) { Date.current + 2.days }

        it 'renders the active reminders count' do
          action

          expect(active_reminders_count).to eq(1)
        end
      end

      context 'when the row has no active reminder' do
        let(:date) { Date.current + 30.days }

        it 'renders zero active reminders instead of null' do
          action

          expect(active_reminders_count).to eq(0)
        end
      end
    end
  end

  describe 'POST delete_records' do
    let(:action) { post :delete_records, params: params, format: :json }
    let(:params) do
      { repository_id: repository.id, selected_rows: [repository_row.id] }
    end

    it 'calls create activity for deleting inventory items' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_item_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'POST archive_rows' do
    let(:action) { post :archive_records, params: params, format: :json }
    let(:params) do
      { repository_id: repository.id, selected_rows: [repository_row.id] }
    end

    context 'when has permission' do
      context 'when archiving passes' do
        it 'change archived boolean to true' do
          action

          expect(repository_row.reload.archived).to be_truthy
        end

        it 'renders 200' do
          action

          expect(response).to have_http_status(:ok)
        end
      end

      context 'when archiving fails' do
        before do
          # Make invalid row record
          repository_row.name = ''
          repository_row.save(validate: false)
        end

        it 'does not change archived boolean to true' do
          action

          expect(repository_row.reload.archived).to be_falsey
        end

        it 'renders 422' do
          action

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when does not have permission' do
      context 'when guest' do
        it 'renders 403' do
          repository.user_assignments.update(user_role: viewer_role)
          action
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when does not see repository' do
        let(:repository) { create :repository, team: team_two, created_by: user_two }

        it 'renders 404' do
          action

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST restore_rows' do
    let(:repository_row) { create :repository_row, :archived, repository: repository, created_by: user }
    let(:action) { post :restore_records, params: params, format: :json }
    let(:params) do
      { repository_id: repository.id, selected_rows: [repository_row.id] }
    end

    context 'when has permission' do
      context 'when restoring passes' do
        it 'change archived boolean to false' do
          action

          expect(repository_row.reload.archived).to be_falsey
        end

        it 'renders 200' do
          action

          expect(response).to have_http_status(:ok)
        end
      end

      context 'when restoring fails' do
        before do
          # Make invalid row record
          repository_row.name = ''
          repository_row.save(validate: false)
        end

        it 'does not change archived boolean to false' do
          action

          expect(repository_row.reload.archived).to be_truthy
        end

        it 'renders 422' do
          action

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when does not have permission' do
      context 'when guest' do
        it 'renders 403' do
          repository.user_assignments.update(user_role: viewer_role)
          action
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when does not see repository' do
        let(:repository) { create :repository, team: team_two, created_by: user_two }

        it 'renders 404' do
          action

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'extra coverage' do
    let(:my_project) { create :project, team: team, created_by: user }
    let(:my_experiment) { create :experiment, project: my_project, created_by: user, last_modified_by: user }
    let(:my_module) { create :my_module, experiment: my_experiment, created_by: user }
    let(:text_column) { create :repository_column, :text_type, repository: repository, created_by: user }

    # serializer root differs between AMS configs; take the collection whatever its key
    def json_list
      body = JSON.parse(response.body)
      body.is_a?(Array) ? body : body.values.find { |v| v.is_a?(Array) }
    end

    def make_guest
      repository.user_assignments.update(user_role: viewer_role)
    end

    describe 'GET #index_ag' do
      it 'returns rows with meta' do
        get :index_ag, params: { repository_id: repository.id, per_page: 10 }, format: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['data'].size).to eq 1
        expect(body['meta']['total_count']).to eq repository.repository_rows_count
      end

      it 'renders custom error when column not found' do
        allow(Lists::RepositoryRowsService).to receive(:new).and_raise(Lists::RepositoryFilters::ColumnNotFoundException)
        get :index_ag, params: { repository_id: repository.id }, format: :json
        expect(JSON.parse(response.body)['custom_error']).to be_present
      end

      it 'renders custom error when value not found' do
        allow(Lists::RepositoryRowsService).to receive(:new).and_raise(Lists::RepositoryFilters::ValueNotFoundException)
        get :index_ag, params: { repository_id: repository.id }, format: :json
        expect(JSON.parse(response.body)['custom_error']).to be_present
      end

      it 'returns 404 for an unreadable repository' do
        get :index_ag, params: { repository_id: repository_two.id }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET #show with my_module' do
      before { allow_any_instance_of(ActionView::Helpers::AssetUrlHelper).to receive(:asset_path) }

      it 'redirects html requests to repository' do
        get :show, params: { repository_id: repository.id, id: repository_row.id }
        expect(response).to redirect_to(repository_path(repository))
      end

      it 'renders json for an assignable module' do
        get :show, format: :json, params: { repository_id: repository.id, id: repository_row.id,
                                            my_module_id: my_module.id }
        expect(response).to have_http_status(:ok)
      end

      it 'renders json when already assigned' do
        create :mm_repository_row, my_module: my_module, repository_row: repository_row, assigned_by: user
        get :show, format: :json, params: { repository_id: repository.id, id: repository_row.id,
                                            my_module_id: my_module.id }
        expect(response).to have_http_status(:ok)
      end

      it 'is forbidden for a repository the user cannot read' do
        make_guest
        repository.user_assignments.destroy_all
        get :show, format: :json, params: { repository_id: repository.id, id: repository_row.id }
        expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
      end
    end

    describe 'GET #assigned_counters' do
      it 'returns counts' do
        create :mm_repository_row, my_module: my_module, repository_row: repository_row, assigned_by: user
        get :assigned_counters, params: { repository_id: repository.id, id: repository_row.id }
        expect(JSON.parse(response.body)).to eq('tasks' => 1, 'experiments' => 1, 'projects' => 1)
      end

      it 'returns 404 for foreign repository' do
        get :assigned_counters, params: { repository_id: repository_two.id, id: repository_row_two.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET #assigned_task_list' do
      it 'returns html' do
        create :mm_repository_row, my_module: my_module, repository_row: repository_row, assigned_by: user
        get :assigned_task_list, params: { repository_id: repository.id, id: repository_row.id, query: '' }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to have_key('html')
      end

      it 'returns 404 for foreign repository' do
        get :assigned_task_list, params: { repository_id: repository_two.id, id: repository_row_two.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET #active_reminder_repository_cells' do
      it 'returns the active reminders of the row' do
        get :active_reminder_repository_cells, params: { repository_id: repository.id, id: repository_row.id }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq('reminders' => [])
      end
    end

    describe 'GET #relationships' do
      it 'returns row, parents and children' do
        get :relationships, params: { repository_id: repository.id, id: repository_row.id }
        body = JSON.parse(response.body)
        expect(body.keys).to match_array(%w(repository_row parents children))
        expect(body['parents']).to eq []
      end

      it 'returns 404 for foreign repository' do
        get :relationships, params: { repository_id: repository_two.id, id: repository_row_two.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET #equipment_booking_events' do
      let!(:past_event) do
        create :calendar_event, team: team, subject: repository_row, created_by: user,
                                start_datetime: 3.days.ago, end_datetime: 2.days.ago
      end
      let!(:future_event) do
        create :calendar_event, team: team, subject: repository_row, created_by: user,
                                start_datetime: 2.days.from_now, end_datetime: 3.days.from_now
      end

      %w(past future).each do |direction|
        it "returns #{direction} events only" do
          get :equipment_booking_events, params: { repository_id: repository.id, id: repository_row.id,
                                                   direction: direction }
          expect(response).to have_http_status(:ok)
          ids = json_list.pluck('id')
          expect(ids.map(&:to_i)).to eq [direction == 'past' ? past_event.id : future_event.id]
        end
      end

      it 'returns all events without direction' do
        get :equipment_booking_events, params: { repository_id: repository.id, id: repository_row.id, page: 1 }
        expect(json_list.size).to eq 2
        expect(JSON.parse(response.body)['meta']['has_next_page']).to be false
      end
    end

    describe 'GET #available_rows' do
      it 'lists active rows' do
        get :available_rows, params: { repository_id: repository.id, q: repository_row.name }, format: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['results'].pluck('id')).to include(repository_row.id)
      end

      it 'responds 422 with message when there are no active rows' do
        repository.repository_rows.destroy_all
        get :available_rows, params: { repository_id: repository.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['no_items']).to be_present
      end

      it 'returns 404 for foreign repository' do
        get :available_rows, params: { repository_id: repository_two.id }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'POST #actions_toolbar' do
      it 'returns actions' do
        post :actions_toolbar, params: { repository_id: repository.id, items: [{ id: repository_row.id }].to_json },
                               format: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['actions']).to be_an(Array)
      end
    end

    describe 'label printing' do
      let(:label_template) do
        ZebraLabelTemplate.create!(team: team, name: 'Template', content: '^XA{{NAME}}^XZ',
                                   width_mm: 10, height_mm: 10, unit: :mm, density: 12)
      end

      it 'rows_to_print returns rows' do
        get :rows_to_print, params: { repository_id: repository.id, row_ids: [repository_row.id] }
        expect(json_list.first['id'].to_i).to eq repository_row.id
      end

      it 'rows_to_print is 404 without rows' do
        get :rows_to_print, params: { repository_id: repository.id, row_ids: [-1] }
        expect(response).to have_http_status(:not_found)
      end

      it 'print_zpl returns rendered labels' do
        get :print_zpl, params: { repository_id: repository.id, row_ids: [repository_row.id],
                                  label_template_id: label_template.id }
        body = JSON.parse(response.body)
        expect(body['labels'].first).to include(repository_row.name)
        expect(body).to have_key('html')
      end

      it 'validate_label_template_columns returns label code' do
        allow(controller).to receive(:current_team).and_return(team)
        post :validate_label_template_columns, params: { repository_id: repository.id, row_ids: [repository_row.id],
                                                         label_template_id: label_template.id }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['label_code']).to include(repository_row.name)
      end

      it 'validate_label_template_columns returns 422 on errors' do
        allow(controller).to receive(:current_team).and_return(team)
        allow_any_instance_of(LabelTemplates::RepositoryRowService)
          .to receive(:render).and_return({ label: 'x', error: ['bad column'] })
        post :validate_label_template_columns, params: { repository_id: repository.id, row_ids: [repository_row.id],
                                                         label_template_id: label_template.id }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq 'bad column'
      end

      it 'print enqueues jobs for the printer' do
        printer = LabelPrinter.create!(name: 'P', type_of: 'fluics', fluics_api_key: 'k', fluics_lid: 'l',
                                       language_type: 'zpl', host: 'h', port: 1) rescue nil
        skip 'label printer cannot be built in this environment' unless printer
        allow(LabelPrinters::PrintJob).to receive(:perform_later).and_return(double(job_id: 'abc'))
        get :print, params: { repository_id: repository.id, row_ids: [repository_row.id],
                              label_template_id: label_template.id, label_printer_id: printer.id, copies: 1 }
        expect(printer.reload.current_print_job_ids).to eq ['abc']
      end
    end

    describe 'POST #create extended' do
      it 'creates a row and assigns it to a module' do
        expect do
          post :create, params: { repository_id: repository.id, repository_row: { name: 'with module' },
                                  my_module_id: my_module.id }, format: :json
        end.to change { repository.repository_rows.count }.by(1)
        expect(response).to have_http_status(:ok)
        expect(my_module.repository_rows.pluck(:name)).to include('with module')
      end

      it 'returns 400 when the name is blank' do
        post :create, params: { repository_id: repository.id, repository_row: { name: '' } }, format: :json
        expect(response).to have_http_status(:bad_request)
      end

      it 'creates a row with a text cell' do
        post :create, params: { repository_id: repository.id, repository_row: { name: 'cells' },
                                repository_cells: { text_column.id.to_s => 'hello' } }, format: :json
        expect(response).to have_http_status(:ok)
        row = repository.repository_rows.find(JSON.parse(response.body).dig('data', 'id'))
        expect(row.repository_cells.first.value.data).to eq 'hello'
      end

      it 'is forbidden for a guest' do
        make_guest
        expect do
          post :create, params: { repository_id: repository.id, repository_row: { name: 'nope' } }, format: :json
        end.not_to(change { RepositoryRow.count })
        expect(response).to have_http_status(:forbidden)
      end

      it 'is blocked while a snapshot is being provisioned' do
        create :repository_snapshot, original_repository: repository, status: :provisioning
        post :create, params: { repository_id: repository.id, repository_row: { name: 'nope' } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'PUT #update extended' do
      it 'renames the row' do
        put :update, params: { repository_id: repository.id, id: repository_row.id,
                               repository_row: { name: 'renamed' } }, format: :json
        expect(response).to have_http_status(:ok)
        expect(repository_row.reload.name).to eq 'renamed'
      end

      it 'is forbidden for a guest' do
        make_guest
        put :update, params: { repository_id: repository.id, id: repository_row.id,
                               repository_row: { name: 'renamed' } }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(repository_row.reload.name).not_to eq 'renamed'
      end

      it 'responds 200 for a blank name (current behaviour: update service does not reject it)' do
        put :update, params: { repository_id: repository.id, id: repository_row.id,
                               repository_row: { name: '' } }, format: :json
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'POST #delete_records extended' do
      it 'deletes rows and reports success' do
        expect do
          post :delete_records, params: { repository_id: repository.id, selected_rows: [repository_row.id] },
                                format: :json
        end.to change { repository.repository_rows.count }.by(-1)
        body = JSON.parse(response.body)
        expect(body['color']).to eq 'success'
      end

      it 'reports partial deletion when some ids are foreign' do
        post :delete_records, params: { repository_id: repository.id,
                                        selected_rows: [repository_row.id, repository_row_two.id] }, format: :json
        expect(JSON.parse(response.body)['color']).to eq 'success'
        expect(RepositoryRow.exists?(repository_row_two.id)).to be true
      end

      it 'reports nothing deleted for foreign ids' do
        post :delete_records, params: { repository_id: repository.id, selected_rows: [repository_row_two.id] },
                              format: :json
        expect(JSON.parse(response.body)['color']).to eq 'info'
      end

      it 'returns 400 without selection' do
        post :delete_records, params: { repository_id: repository.id }, format: :json
        expect(response).to have_http_status(:bad_request)
      end

      it 'is forbidden for a guest' do
        make_guest
        post :delete_records, params: { repository_id: repository.id, selected_rows: [repository_row.id] },
                              format: :json
        expect(response).to have_http_status(:forbidden)
        expect(RepositoryRow.exists?(repository_row.id)).to be true
      end
    end

    describe 'POST #copy_records extended' do
      it 'duplicates the row' do
        expect do
          post :copy_records, params: { repository_id: repository.id, selected_rows: [repository_row.id] },
                              format: :json
        end.to change { repository.repository_rows.count }.by(1)
      end

      it 'is forbidden for a guest' do
        make_guest
        expect do
          post :copy_records, params: { repository_id: repository.id, selected_rows: [repository_row.id] },
                              format: :json
        end.not_to(change { RepositoryRow.count })
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
