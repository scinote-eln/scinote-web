# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDatatableHelper, type: :helper do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:repository) { create(:repository, team: team, created_by: user) }
  let(:my_module) { create(:my_module) }

  let(:text_row) { create(:repository_row, repository: repository, created_by: user) }
  let(:text_cell) { create(:repository_cell, :text_value, repository_row: text_row) }
  let(:text_mappings) { { text_cell.repository_column_id => 'custom_text' } }

  before do
    allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(true)
    allow(RepositoryBase).to receive(:repository_row_connections_enabled?).and_return(true)
    without_partial_double_verification do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can_manage_repository_stock?).and_return(true)
      allow(helper).to receive(:can_read_repository?).and_return(true)
      allow(helper).to receive(:can_update_my_module_stock_consumption?).and_return(true)
    end
  end

  # Builds rows through a real query that selects the same SQL aliases the datatable services add
  # (counts, consumed stock, creator/modifier/archiver names), so a renamed alias fails here.
  def aliased_rows(*rows, reminders: false)
    RepositoryRow
      .where(id: rows.map(&:id))
      .order(:id)
      .joins('LEFT OUTER JOIN users created_by ON created_by.id = repository_rows.created_by_id')
      .joins('LEFT OUTER JOIN users last_modified_by ON last_modified_by.id = repository_rows.last_modified_by_id')
      .joins('LEFT OUTER JOIN users archived_by ON archived_by.id = repository_rows.archived_by_id')
      .select('repository_rows.*',
              'created_by.full_name AS created_by_full_name',
              'last_modified_by.full_name AS last_modified_by_full_name',
              'archived_by.full_name AS archived_by_full_name',
              "#{reminders ? 'TRUE' : 'FALSE'} AS has_active_reminders",
              '(SELECT COUNT(*) FROM my_module_repository_rows mmrr ' \
              'WHERE mmrr.repository_row_id = repository_rows.id) AS assigned_my_modules_count',
              '(SELECT COUNT(DISTINCT m.experiment_id) FROM my_module_repository_rows mmrr ' \
              'JOIN my_modules m ON m.id = mmrr.my_module_id ' \
              'WHERE mmrr.repository_row_id = repository_rows.id) AS assigned_experiments_count',
              '(SELECT COUNT(DISTINCT e.project_id) FROM my_module_repository_rows mmrr ' \
              'JOIN my_modules m ON m.id = mmrr.my_module_id JOIN experiments e ON e.id = m.experiment_id ' \
              'WHERE mmrr.repository_row_id = repository_rows.id) AS assigned_projects_count',
              '(SELECT SUM(mmrr.stock_consumption) FROM my_module_repository_rows mmrr ' \
              'WHERE mmrr.repository_row_id = repository_rows.id) AS consumed_stock')
      .to_a
  end

  def stub_permission(method_name, value)
    without_partial_double_verification { allow(helper).to receive(method_name).and_return(value) }
  end

  # A consumption cell holds a RepositoryStockConsumptionValue (the column data type must match the value class),
  # while the row association looks for the RepositoryStockValue base type.
  def create_consumption_cell(row, column)
    cell = build(:repository_cell, repository_row: row, repository_column: column)
    cell.value = build(:repository_stock_value, repository_cell: cell).becomes(RepositoryStockConsumptionValue)
    cell.save!
    cell
  end

  def stock_column(decimals: '2')
    create(:repository_column, :stock_type, repository: repository, metadata: { 'decimals' => decimals })
  end

  describe '#prepare_row_columns' do
    it 'builds the default columns, urls and custom cell values for each row' do
      text_cell
      text_row.update_columns(parent_connections_count: 1, child_connections_count: 3)
      row = helper.prepare_row_columns(aliased_rows(text_row), repository, text_mappings, team).first

      expect(row['DT_RowId']).to eq text_row.id
      expect(row[:'4']).to eq '1 / 3'
      expect(row[:'6']).to eq user.full_name
      expect(row['code']).to eq text_row.code
      expect(row[:'3']).to eq text_row.name
      expect(row['DT_RowAttr'][:'data-state']).to eq []
      expect(row['recordInfoUrl']).to include(text_row.id.to_s)
      expect(row['rowRemindersUrl']).to include('active_reminder')
      expect(row['relationships_enabled']).to be true
      expect(row['recordUpdateUrl']).to be_present
      expect(row['recordEditable']).to eq text_row.editable?
      expect(row['custom_text'][:value][:view]).to eq text_cell.value.data
      expect(row).not_to have_key('stock')
    end

    it 'does not add update url and editable flag in view mode' do
      text_cell
      row = helper.prepare_row_columns(aliased_rows(text_row), repository, text_mappings, team, view_mode: true).first

      expect(row).not_to have_key('recordUpdateUrl')
      expect(row).not_to have_key('recordEditable')
    end

    it 'assumes rows are editable when omit_editable is given' do
      row = helper.prepare_row_columns(aliased_rows(text_row), repository, {}, team, omit_editable: true).first
      expect(row['recordEditable']).to be true
    end

    it 'exposes the reminder flag when reminders are enabled' do
      allow(Repository).to receive(:reminders_enabled?).and_return(true)
      active = helper.prepare_row_columns(aliased_rows(text_row, reminders: true), repository, {}, team).first
      inactive = helper.prepare_row_columns(aliased_rows(text_row), repository, {}, team).first
      expect(active['hasActiveReminders']).to be true
      expect(inactive['hasActiveReminders']).to be false
    end

    it 'adds a stock url with managable flag when the row has no stock cell yet' do
      stock_column
      row = helper.prepare_row_columns(aliased_rows(text_row), repository, {}, team).first

      expect(row['stock'][:stock_url]).to include('new')
      expect(row['stock'][:stock_managable]).to be true
      expect(row['stock']['displayWarnings']).to be true
      expect(row['stock'][:stock_status]).to be_nil
      expect(row['stock']['value_type']).to eq 'RepositoryStockValue'
    end

    it 'serializes the existing stock cell and excludes it from custom columns' do
      column = stock_column
      stock_cell = create(:repository_cell, :stock_value, repository_row: text_row,
                                                          repository_column: column)
      row = helper.prepare_row_columns(aliased_rows(text_row), repository,
                                       { stock_cell.repository_column_id => 'stock_custom' }, team).first

      expect(row).not_to have_key('stock_custom')
      expect(row['stock']).to be_present
      expect(row['stock']['value_type']).to eq 'RepositoryStockValue'
    end

    it 'disables stock management in the row when the caller asks for it' do
      stock_column
      row = helper.prepare_row_columns(aliased_rows(text_row), repository, {}, team,
                                       disable_stock_management: true).first
      expect(row['stock'][:stock_managable]).to be false
    end

    it 'adds stock consumption details when requested for a module' do
      column = stock_column(decimals: '2')
      create(:repository_cell, :stock_value, repository_row: text_row, repository_column: column)
      mmrr = MyModuleRepositoryRow.create!(repository_row: text_row, my_module: my_module, assigned_by: user)
      mmrr.update_columns(stock_consumption: 4.5)
      rows = aliased_rows(text_row)

      row = helper.prepare_row_columns(rows, repository, {}, team,
                                       include_stock_consumption: true,
                                       my_module: my_module).first

      consumed = row['consumedStock']
      expect(consumed[:stock_present]).to be true
      expect(consumed[:consumptionPermitted]).to be true
      expect(consumed[:consumptionManagable]).to be true
      expect(consumed[:updateStockConsumptionUrl]).to include(my_module.id.to_s)
      expect(consumed[:value][:consumed_stock]).to eq 4.5
      expect(consumed[:value][:consumed_stock_formatted]).to start_with('4.5')
    end

    it 'denies stock consumption when the user cannot update module stock consumption' do
      column = stock_column
      create(:repository_cell, :stock_value, repository_row: text_row, repository_column: column)
      stub_permission(:can_update_my_module_stock_consumption?, false)

      row = helper.prepare_row_columns(aliased_rows(text_row), repository, {}, team,
                                       include_stock_consumption: true,
                                       my_module: my_module).first

      expect(row['consumedStock'][:consumptionPermitted]).to be false
    end

    it 'marks consumption as not managable for archived rows' do
      column = stock_column
      create(:repository_cell, :stock_value, repository_row: text_row, repository_column: column)
      archived_row = create(:repository_row, :archived, repository: repository, created_by: user)
      create(:repository_cell, :stock_value, repository_row: archived_row, repository_column: column)

      row = helper.prepare_row_columns(aliased_rows(archived_row), repository, {}, team,
                                       include_stock_consumption: true,
                                       my_module: my_module).first

      expect(row['DT_RowAttr'][:'data-state']).to include(:archived)
      expect(row['consumedStock'][:consumptionManagable]).to be false
    end

    it 'serializes the stock cell when stock management is disabled but the column exists' do
      column = stock_column
      create(:repository_cell, :stock_value, repository_row: text_row, repository_column: column)
      allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(false)

      row = helper.prepare_row_columns(aliased_rows(text_row), repository, {}, team).first

      expect(row['stock']).to be_present
      expect(row['stock']).not_to have_key('stock_url')
    end
  end

  describe '#prepare_simple_view_row_columns' do
    let(:simple_row) { create(:repository_row, repository: repository, created_by: user, name: 'Sample <b>name</b>') }

    it 'returns the name and urls for each row' do
      row = helper.prepare_simple_view_row_columns(aliased_rows(simple_row), repository, my_module).first

      expect(row[:DT_RowId]).to eq simple_row.id
      expect(row[:'0']).to eq ERB::Util.html_escape('Sample <b>name</b>')
      expect(row[:recordInfoUrl]).to include(simple_row.id.to_s)
      expect(row[:rowRemindersUrl]).to include('active_reminder')
    end

    it 'exposes the reminder flag unless reminders are disabled' do
      allow(Repository).to receive(:reminders_enabled?).and_return(true)
      enabled = helper.prepare_simple_view_row_columns(aliased_rows(simple_row, reminders: true), repository,
                                                       my_module).first
      disabled = helper.prepare_simple_view_row_columns(aliased_rows(simple_row, reminders: true), repository, my_module,
                                                        disable_reminders: true).first

      expect(enabled['hasActiveReminders']).to be true
      expect(disabled).not_to have_key('hasActiveReminders')
    end

    it 'returns only the code for rows the user cannot read' do
      stub_permission(:can_read_repository?, false)
      row = helper.prepare_simple_view_row_columns(aliased_rows(simple_row), repository, my_module).first

      expect(row).to eq(code: simple_row.code)
    end

    it 'shows unreadable rows on a shared link view when the module is shared' do
      stub_permission(:can_read_repository?, false)
      allow(my_module).to receive(:shared?).and_return(true)
      row = helper.prepare_simple_view_row_columns(aliased_rows(simple_row), repository, my_module,
                                                   shareable_link_view: true).first

      expect(row[:DT_RowId]).to eq simple_row.id
    end

    it 'adds the stock values and consumption details when stock management is on' do
      column = stock_column(decimals: '1')
      create(:repository_cell, :stock_value, repository_row: simple_row, repository_column: column)

      row = helper.prepare_simple_view_row_columns(aliased_rows(simple_row), repository, my_module).first

      expect(row['stock']).to be_present
      expect(row['stock'][:stock_managable]).to be false
      expect(row['stock']['displayWarnings']).to be true
      expect(row['consumedStock']['stock_present']).to be true
      expect(row['consumedStock']['consumptionPermitted']).to be true
      expect(row['consumedStock']['consumptionManagable']).to be true
      expect(row['consumedStock'][:value][:consumed_stock_formatted]).to be_a(String)
      expect(row['consumedStock']['updateStockConsumptionUrl']).to include(my_module.id.to_s)
    end

    it 'reports no stock presence but keeps the consume url when the row has no stock cell' do
      stock_column
      row = helper.prepare_simple_view_row_columns(aliased_rows(simple_row), repository, my_module).first

      expect(row['stock'][:stock_managable]).to be false
      expect(row['consumedStock']['stock_present']).to be false
      expect(row['consumedStock']['consumptionManagable']).to be true
      expect(row['consumedStock']['updateStockConsumptionUrl']).to include(my_module.id.to_s)
    end
  end

  describe '#prepare_snapshot_row_columns' do
    let(:snapshot) { create(:repository_snapshot, original_repository: repository, my_module: my_module) }

    it 'returns the frozen snapshot columns and custom values for each row' do
      text_cell
      allow(snapshot).to receive(:has_stock_management?).and_return(false)
      row = helper.prepare_snapshot_row_columns(aliased_rows(text_row), text_mappings, team, snapshot, my_module).first

      expect(row[:DT_RowId]).to eq text_row.id
      expect(row[:'1']).to eq text_row.code
      expect(row[:'2']).to eq text_row.name
      expect(row[:'3']).to eq I18n.l(text_row.created_at, format: :full)
      expect(row[:'4']).to eq user.full_name
      expect(row[:recordInfoUrl]).to include(snapshot.id.to_s)
      expect(row['custom_text'][:value][:view]).to eq text_cell.value.data
      expect(row).not_to have_key('stock')
    end

    it 'adds stock and consumed stock placeholders when the snapshot has stock management' do
      allow(snapshot).to receive(:has_stock_management?).and_return(true)
      row = helper.prepare_snapshot_row_columns(aliased_rows(text_row), {}, team, snapshot, my_module).first

      expect(row['stock']).to eq(value_type: 'RepositoryStockValue')
      expect(row['consumedStock']).to eq({})
    end

    it 'serializes existing stock and consumption cells for a snapshot' do
      column = stock_column
      create(:repository_cell, :stock_value, repository_row: text_row, repository_column: column)
      allow(snapshot).to receive(:has_stock_management?).and_return(true)

      row = helper.prepare_snapshot_row_columns(aliased_rows(text_row), {}, team, snapshot, my_module).first

      expect(row['stock']).to be_present
      expect(row).to have_key('consumedStock')
    end

    it 'serializes the consumed stock cell of a row when the snapshot has one' do
      create(:repository_cell, :stock_value, repository_row: text_row, repository_column: stock_column)
      consumption_column = create(:repository_column, repository: repository,
                                                      data_type: 'RepositoryStockConsumptionValue')
      create_consumption_cell(text_row, consumption_column)
      allow(snapshot).to receive(:has_stock_management?).and_return(true)

      row = helper.prepare_snapshot_row_columns(aliased_rows(text_row), {}, team, snapshot, my_module).first

      expect(row['consumedStock']).not_to eq({})
      expect(row['consumedStock'][:value]).to be_present
    end
  end

  describe '#assigned_row' do
    it 'returns the assignment counts and the task list url' do
      record = double('row', repository: repository, assigned_my_modules_count: 3,
                             assigned_experiments_count: 2, assigned_projects_count: 1)
      allow(record).to receive(:to_param).and_return(text_row.id.to_s)

      result = helper.assigned_row(record)

      expect(result).to include(tasks: 3, experiments: 2, projects: 1)
      expect(result[:task_list_url]).to include('task_list')
    end
  end

  describe 'default column builders' do
    let(:now) { Time.zone.parse('2024-03-04 10:20:30') }
    let(:record) do
      double('row', repository: repository, code: 'RS1', name: 'Name <i>x</i>',
                    parent_connections_count: nil, child_connections_count: 2,
                    created_at: now, created_by_full_name: 'Ana', updated_at: nil,
                    last_modified_by_full_name: 'Bob', archived_on: nil, archived_by_full_name: 'Cy',
                    external_id: 'EXT-1', assigned_my_modules_count: 0,
                    assigned_experiments_count: 0, assigned_projects_count: 0).tap do |d|
        allow(d).to receive(:to_param).and_return('1')
      end
    end

    it 'builds repository default columns with escaped text and empty optional dates' do
      columns = helper.repository_default_columns(record)

      expect(columns[:'2']).to eq 'RS1'
      expect(columns[:'3']).to eq ERB::Util.html_escape('Name <i>x</i>')
      expect(columns[:'4']).to eq '0 / 2'
      expect(columns[:'5']).to eq I18n.l(now, format: :full)
      expect(columns[:'6']).to eq 'Ana'
      expect(columns[:'7']).to eq ''
      expect(columns[:'8']).to eq 'Bob'
      expect(columns[:'9']).to eq ''
      expect(columns[:'10']).to eq 'Cy'
    end

    it 'formats the updated and archived dates when present' do
      allow(record).to receive(:updated_at).and_return(now)
      allow(record).to receive(:archived_on).and_return(now)
      columns = helper.repository_default_columns(record)

      expect(columns[:'7']).to eq I18n.l(now, format: :full)
      expect(columns[:'9']).to eq I18n.l(now, format: :full)
    end

    it 'builds soft locked default columns with the same layout' do
      columns = helper.soft_locked_repository_default_columns(record)

      expect(columns.keys).to eq %i(1 2 3 4 5 6 7 8 9 10)
      expect(columns[:'4']).to eq '0 / 2'
    end

    it 'builds linked repository default columns with the external id' do
      columns = helper.linked_repository_default_columns(record)

      expect(columns.keys).to eq %i(1 2 3 4 5 6 7 8)
      expect(columns[:'8']).to eq 'EXT-1'
      expect(columns[:'6']).to eq ''
    end
  end

  describe '#serialize_repository_cell_value' do
    it 'uses the serializer for the column data type and passes the scope' do
      cell = double('cell', value: 'value', repository_column: double('column', data_type: 'RepositoryTextValue'))
      serializer = double('serializer', serializable_hash: { value: 'x' })
      expect(RepositoryDatatable::RepositoryTextValueSerializer).to receive(:new).with(
        'value',
        scope: hash_including(team: team, user: user, repository: repository, options: { reminders_enabled: true })
      ).and_return(serializer)

      expect(helper.serialize_repository_cell_value(cell, team, repository, reminders_enabled: true))
        .to eq(value: 'x')
    end

    it 'selects the serializer matching each core repository value type' do
      {
        'RepositoryTextValue' => 'RepositoryTextValueSerializer',
        'RepositoryNumberValue' => 'RepositoryNumberValueSerializer',
        'RepositoryListValue' => 'RepositoryListValueSerializer',
        'RepositoryChecklistValue' => 'RepositoryChecklistValueSerializer',
        'RepositoryStatusValue' => 'RepositoryStatusValueSerializer',
        'RepositoryTimeValue' => 'RepositoryTimeValueSerializer',
        'RepositoryDateValue' => 'RepositoryDateValueSerializer',
        'RepositoryDateTimeValue' => 'RepositoryDateTimeValueSerializer',
        'RepositoryDateRangeValue' => 'RepositoryDateRangeValueSerializer',
        'RepositoryTimeRangeValue' => 'RepositoryTimeRangeValueSerializer',
        'RepositoryDateTimeRangeValue' => 'RepositoryDateTimeRangeValueSerializer',
        'RepositoryAssetValue' => 'RepositoryAssetValueSerializer',
        'RepositoryStockValue' => 'RepositoryStockValueSerializer',
        'RepositoryStockConsumptionValue' => 'RepositoryStockConsumptionValueSerializer'
      }.each do |data_type, serializer_name|
        serializer_class = "RepositoryDatatable::#{serializer_name}".constantize
        cell = double('cell', value: 'v', repository_column: double('column', data_type: data_type))
        expect(serializer_class).to receive(:new).and_return(double('serializer', serializable_hash: { type: data_type }))

        expect(helper.serialize_repository_cell_value(cell, team, repository)).to eq(type: data_type)
      end
    end

    it 'uses the serializer registered by extensions for unknown value types' do
      cell = double('cell', value: 'v', value_type: 'RepositoryFancyValue',
                            repository_column: double('column', data_type: 'RepositoryFancyValue'))
      serializer_class = double('extra_serializer')
      serializer = double('serializer', serializable_hash: { extra: true })
      stub_const('Extends::REPOSITORY_EXTRA_VALUE_SERIALIZERS', { 'RepositoryFancyValue' => serializer_class })
      expect(serializer_class).to receive(:new).and_return(serializer)

      expect(helper.serialize_repository_cell_value(cell, team, repository)).to eq(extra: true)
    end
  end

  describe '#row_style' do
    it 'returns archived for archived rows' do
      row = create(:repository_row, :archived, repository: repository, created_by: user)
      expect(helper.row_style(row, nil)).to eq [:archived]
    end

    it 'returns an empty list for active rows without output' do
      expect(helper.row_style(text_row, nil)).to eq []
    end
  end

  describe '#stock_consumption_permitted?' do
    it 'is false for snapshots and when there is no user' do
      snapshot = create(:repository_snapshot, original_repository: repository, my_module: my_module)
      expect(helper.stock_consumption_permitted?(snapshot, my_module)).to be false

      without_partial_double_verification { allow(helper).to receive(:current_user).and_return(nil) }
      expect(helper.stock_consumption_permitted?(repository, my_module)).to be false
    end

    it 'delegates to the module stock consumption permission' do
      expect(helper.stock_consumption_permitted?(repository, my_module)).to be true
      stub_permission(:can_update_my_module_stock_consumption?, false)
      expect(helper.stock_consumption_permitted?(repository, my_module)).to be false
    end
  end

  describe '#stock_consumption_managable?' do
    it 'is false without a module, and for archived repositories or rows' do
      expect(helper.stock_consumption_managable?(text_row, repository, nil)).to be false
      expect(helper.stock_consumption_managable?(text_row, repository, my_module)).to be true

      archived_repository = create(:repository, team: team, created_by: user, archived: true,
                                                archived_on: Time.zone.now, archived_by: user)
      expect(helper.stock_consumption_managable?(text_row, archived_repository, my_module)).to be false

      archived_row = create(:repository_row, :archived, repository: repository, created_by: user)
      expect(helper.stock_consumption_managable?(archived_row, repository, my_module)).to be false
    end
  end

  describe '#display_stock_warnings?' do
    it 'shows warnings for live repositories but not for snapshots' do
      expect(helper.display_stock_warnings?(repository)).to be true
      snapshot = create(:repository_snapshot, original_repository: repository, my_module: my_module)
      expect(helper.display_stock_warnings?(snapshot)).to be false
    end
  end
end
