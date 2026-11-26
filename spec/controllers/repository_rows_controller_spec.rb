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
      state: {}
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

  describe 'GET new' do
    let(:action) { get :new, params: { repository_id: repository.id }, format: :json }
    let!(:text_column) { create :repository_column, :text_type, repository: repository }
    let!(:list_column) { create :repository_column, :list_type, repository: repository }
    let!(:list_item) { create :repository_list_item, repository_column: list_column, data: 'Option A' }
    let!(:stock_column) { create :repository_column, :stock_type, repository: repository }
    let!(:unit_item) { create :repository_stock_unit_item, repository_column: stock_column, data: 'ml' }
    let(:column_defs) { response.parsed_body['column_defs'].index_by { |column| column['id'] } }

    before { allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(true) }

    it 'lists the columns in the order of the saved table state, hidden ones included' do
      user.user_settings.create!(
        key: "repository_table_#{repository.id}_active_table_state",
        value: { 'columnsState' => [{ 'colId' => 'stock', 'hide' => false },
                                    { 'colId' => "col_#{text_column.id}", 'hide' => true }] }
      )

      action

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['column_defs'].pluck('id')).to eq([stock_column.id, text_column.id, list_column.id])
    end

    it 'gives list columns their items and the stock column its units' do
      action

      expect(column_defs[list_column.id]['column_items']).to eq([{ 'id' => list_item.id, 'label' => 'Option A' }])
      expect(column_defs[stock_column.id]['column_items']).to eq([{ 'id' => unit_item.id, 'label' => 'ml' }])
    end

    it 'allows managing stock' do
      action

      expect(response.parsed_body['can_manage_stock']).to be(true)
    end

    it 'does not allow managing stock when stock management is disabled' do
      allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(false)

      action

      expect(response.parsed_body['can_manage_stock']).to be(false)
    end

    it 'renders 403 when the user cannot create items' do
      repository.user_assignments.update(user_role: viewer_role)

      action

      expect(response).to have_http_status(:forbidden)
    end

    it 'renders 404 for a repository the user cannot read' do
      get :new, params: { repository_id: repository_two.id }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    context 'when duplicating an item' do
      let(:action) do
        get :new, params: { repository_id: repository.id, row_to_duplicate_id: repository_row.id }, format: :json
      end

      before do
        repository_row.update!(name: 'Original')
        RepositoryCell.create_with_value!(repository_row, text_column, 'Lot 42', user)
      end

      it 'returns the values that prefill the item card' do
        action

        row_to_duplicate = response.parsed_body['row_to_duplicate']
        expect(row_to_duplicate['name']).to eq('Original (1)')
        expect(row_to_duplicate['cells'][text_column.id.to_s]['value']['edit']).to eq('Lot 42')
        expect(row_to_duplicate['errors']).to eq({})
      end

      it 'returns the failed unique validations' do
        text_column.update!(enforce_unique: true)
        repository.update!(enforce_unique_item_names: true)
        create :repository_row, name: 'Original (1)', repository: repository, created_by: user

        action

        errors = response.parsed_body['row_to_duplicate']['errors']
        expect(errors['name']).to eq(['An item with this name already exists'])
        expect(errors['unique_cells']).to eq(text_column.id.to_s => ['An item with this value already exists'])
      end

      it 'renders 404 for an item of another repository' do
        get :new, params: { repository_id: repository.id, row_to_duplicate_id: repository_row_two.id }, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #copy_records' do
    let!(:other_row) { create :repository_row, repository: repository, created_by: user, last_modified_by: user }
    let(:action) do
      post :copy_records, params: { repository_id: repository.id, selected_rows: [repository_row.id, other_row.id] }
    end

    it 'returns a success response' do
      post :copy_records, params: { repository_id: repository.id,
                                    selected_rows: [repository_row.id] }
      expect(response).to have_http_status(:success)
    end

    it 'refuses items with an empty mandatory column' do
      create :repository_column, :text_type, repository: repository, mandatory: true

      expect { action }.not_to(change { RepositoryRow.count })
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['flash']).to include('at least one mandatory column is empty')
    end

    it 'refuses items whose duplicates would break unique values' do
      unique_column = create :repository_column, :text_type, repository: repository, enforce_unique: true
      RepositoryCell.create_with_value!(other_row, unique_column, 'Lot 42', user)

      expect { action }.not_to(change { RepositoryRow.count })
      expect(response.parsed_body['flash']).to include('at least one column requires unique values')
    end
  end

  describe 'POST #actions_toolbar' do
    let(:other_row) { create :repository_row, repository: repository, created_by: user, last_modified_by: user }
    let(:duplicate_action) do
      post :actions_toolbar, params: { repository_id: repository.id, items: items.map { |id| { id: id } }.to_json },
                             format: :json
      response.parsed_body['actions'].find { |action| action['name'] == 'duplicate' }
    end

    before { create :repository_column, :text_type, repository: repository, mandatory: true }

    context 'with multiple items' do
      let(:items) { [repository_row.id, other_row.id] }

      it 'disables duplicating with a tooltip when validations fail' do
        expect(duplicate_action['disabled']).to be true
        expect(duplicate_action['tooltip']).to include('at least one mandatory column is empty')
      end
    end

    context 'with a single item' do
      let(:items) { [repository_row.id] }

      it 'keeps duplicating enabled regardless of failed validations' do
        expect(duplicate_action).to be_present
        expect(duplicate_action['disabled']).to be_nil
      end
    end
  end

  describe 'POST #duplicate' do
    let!(:text_column) { create :repository_column, :text_type, repository: repository }
    let(:params) { { repository_id: repository.id, id: repository_row.id, repository_row: { name: 'Copy' } } }
    let(:action) { post :duplicate, params: params, format: :json }

    before { RepositoryCell.create_with_value!(repository_row, text_column, 'Lot 42', user) }

    it 'creates the item with the values of the original' do
      action

      expect(response).to have_http_status(:success)
      copy = repository.repository_rows.find_by!(name: 'Copy')
      expect(copy.repository_cells.first.value.data).to eq('Lot 42')
    end

    it 'logs the duplicate activity' do
      expect(Activities::CreateActivityService)
        .to(receive(:call).with(hash_including(activity_type: :copy_inventory_item)))

      action
    end

    it 'returns the failed unique validations' do
      text_column.update!(enforce_unique: true)

      expect { action }.not_to(change { RepositoryRow.count })
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['unique_cells']).to eq(text_column.id.to_s => ['An item with this value already exists'])
    end

    it 'renders 404 for an item of another repository' do
      params[:id] = repository_row_two.id

      action

      expect(response).to have_http_status(:not_found)
    end

    it 'renders 403 when the user cannot create items' do
      repository.user_assignments.update(user_role: viewer_role)

      action

      expect(response).to have_http_status(:forbidden)
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

    context 'with the cell values of the new item card' do
      let!(:text_column) { create :repository_column, :text_type, repository: repository }
      let!(:checklist_column) { create :repository_column, :checklist_type, repository: repository }
      let!(:checklist_items) { create_list :repository_checklist_item, 2, repository_column: checklist_column }
      let!(:date_range_column) { create :repository_column, :date_range_type, repository: repository }
      let(:params) do
        { repository_id: repository.id,
          repository_row: { name: 'New item' },
          repository_cells: {
            text_column.id.to_s => 'Some text',
            checklist_column.id.to_s => checklist_items.map { |item| item.id.to_s },
            date_range_column.id.to_s => { start_time: '2026-03-02', end_time: '2026-03-06' }
          } }
      end

      it 'creates the item with array and nested values intact' do
        action

        values = repository.repository_rows.find_by!(name: 'New item')
                           .repository_cells.index_by(&:repository_column_id).transform_values(&:value)
        expect(values[text_column.id].data).to eq('Some text')
        expect(values[checklist_column.id].repository_checklist_items).to match_array(checklist_items)
        expect(values[date_range_column.id].start_time.to_date).to eq(Date.new(2026, 3, 2))
        expect(values[date_range_column.id].end_time.to_date).to eq(Date.new(2026, 3, 6))
      end
    end

    context 'with a stock value' do
      let!(:stock_column) { create :repository_column, :stock_type, repository: repository }
      let!(:unit_item) { create :repository_stock_unit_item, repository_column: stock_column, data: 'ml' }
      let(:stock_payload) do
        { amount: '12.5', unit_item_id: unit_item.id, low_stock_threshold: '2', comment: 'Initial delivery' }
      end
      let(:params) do
        { repository_id: repository.id,
          repository_row: { name: 'Stocked item' },
          repository_cells: { stock_column.id.to_s => stock_payload } }
      end

      before { allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(true) }

      it 'creates the stock value with a ledger record that carries the comment' do
        action

        stock_value = repository.repository_rows.find_by!(name: 'Stocked item').repository_stock_value
        expect(stock_value).to have_attributes(amount: BigDecimal('12.5'),
                                               low_stock_threshold: BigDecimal('2'),
                                               repository_stock_unit_item: unit_item)
        expect(stock_value.repository_ledger_records.sole)
          .to have_attributes(amount: BigDecimal('12.5'), unit: 'ml', comment: 'Initial delivery')
      end

      it 'logs the initial stock' do
        action

        expect(Activity.find_by!(type_of: :inventory_item_stock_set).message_items)
          .to include('new_amount' => '12.5', 'unit' => 'ml', 'comment' => 'Initial delivery')
      end

      it 'renders 403 and creates nothing when stock management is disabled' do
        allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(false)

        expect { action }.not_to(change { [RepositoryRow.count, RepositoryStockValue.count] })
        expect(response).to have_http_status(:forbidden)
      end

      context 'when the user can create items but not manage stock' do
        let(:creator_role) do
          create :user_role, name: 'Item creator', created_by: user, last_modified_by: user,
                             permissions: [RepositoryPermissions::READ, RepositoryPermissions::ROWS_CREATE]
        end

        before { repository.user_assignments.update(user_role: creator_role) }

        it 'renders 403 and creates nothing' do
          expect { action }.not_to(change { [RepositoryRow.count, RepositoryStockValue.count] })
          expect(response).to have_http_status(:forbidden)
        end

        it 'renders 403 when the stock column id is zero-padded to slip past the check' do
          params[:repository_cells] = { "0#{stock_column.id}" => stock_payload }

          expect { action }.not_to(change { RepositoryStockValue.count })
          expect(response).to have_http_status(:forbidden)
        end

        it 'still creates items without a stock value' do
          params[:repository_cells] = {}

          expect { action }.to change { RepositoryRow.count }.by(1)
        end
      end
    end

    context 'with a task (my_module_id)' do
      # The item card opened from a task posts a JSON body, so is_output arrives as a real boolean.
      let(:action) { post :create, params: params, as: :json }
      let!(:project) { create :project, team: team, created_by: user }
      let!(:experiment) { create :experiment, project: project, created_by: user }
      let!(:my_module) { create :my_module, experiment: experiment, created_by: user }
      let!(:text_column) { create :repository_column, :text_type, repository: repository, mandatory: true }
      let(:is_output) { true }
      let(:params) do
        { repository_id: repository.id,
          repository_row: { name: 'Task item' },
          repository_cells: { text_column.id.to_s => 'Lot 7' },
          my_module_id: my_module.id,
          is_output: is_output }
      end
      let(:created_row) { repository.repository_rows.find_by!(name: 'Task item') }

      it 'creates the item as an output of the task, assigns it and saves the cell value' do
        expect { action }.to change { RepositoryRow.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(created_row.output?).to be(true)
        expect(created_row.my_module_id).to eq(my_module.id)
        expect(created_row.my_module_repository_rows.pluck(:my_module_id)).to eq([my_module.id])
        expect(created_row.repository_cells.find_by!(repository_column: text_column).value.data).to eq('Lot 7')
      end

      context 'when is_output is false' do
        let(:is_output) { false }

        it 'assigns the item to the task without marking it as an output' do
          expect { action }.to change { RepositoryRow.count }.by(1)

          expect(response).to have_http_status(:ok)
          expect(created_row.output?).to be(false)
          expect(created_row.my_module_repository_rows.pluck(:my_module_id)).to eq([my_module.id])
        end
      end

      it 'renders 400 and creates nothing when the mandatory column has no value' do
        params[:repository_cells] = {}

        expect { action }.not_to(change { [RepositoryRow.count, MyModuleRepositoryRow.count] })
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body['repository_cells'])
          .to eq([I18n.t('repositories.mandatory_column.missing_value', column: text_column.name)])
      end
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

  describe 'unique item names' do
    before do
      repository.update!(enforce_unique_item_names: true)
      repository_row.update!(name: 'Existing item')
    end

    describe 'POST create' do
      let(:action) do
        post :create, params: { repository_id: repository.id, repository_row: { name: ' existing ITEM ' } }, format: :json
      end

      it 'rejects a duplicate name' do
        expect { action }.not_to change(RepositoryRow, :count)
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body['name']).to eq(['An item with this name already exists'])
      end
    end

    describe 'PUT update' do
      let!(:other_row) do
        create :repository_row, name: 'Other item', repository: repository, created_by: user, last_modified_by: user
      end
      let(:action) do
        put :update, params: { repository_id: repository.id, id: other_row.id,
                               repository_row: { name: 'existing item' } }, format: :json
      end

      it 'rejects renaming to a duplicate name' do
        action

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body['name']).to eq(['An item with this name already exists'])
        expect(other_row.reload.name).to eq 'Other item'
      end
    end
  end

  describe 'unique entries in text columns' do
    let!(:text_column) do
      create :repository_column, :text_type, repository: repository, created_by: user,
                                             enforce_unique: true, unique_case_sensitive: false
    end
    let(:action) do
      post :create, params: { repository_id: repository.id, repository_row: { name: 'New item' },
                              repository_cells: { text_column.id => 'lot 42' } }, format: :json
    end

    before { RepositoryCell.create_with_value!(repository_row, text_column, 'Lot 42', user) }

    it 'rejects an item with a duplicate value' do
      expect { action }.not_to change(RepositoryRow, :count)
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['unique_cells']).to eq(text_column.id.to_s => ['An item with this value already exists'])
    end
  end
end
