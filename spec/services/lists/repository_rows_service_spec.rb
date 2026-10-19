# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lists::RepositoryRowsService do

  before(:all) do
    team = create(:team)
    user = create(:user)
    repository = create(:repository, created_by: user)
    text_column = create(:repository_column, :text_type, repository: repository, created_by: user)

    10.times do
      repository_rows = build_list(:repository_row, 10, repository: repository, created_by: repository.created_by, last_modified_by: repository.created_by)
      result = RepositoryRow.import(repository_rows, validate: false)
      repository_rows = RepositoryRow.where(id: result.ids)
      repository_text_values = []
      repository_rows.each do |repository_row|
        repository_text_values << build(:repository_text_value, data: Faker::Name.name, created_by: user, repository_cell_attributes: { repository_row: repository_row, repository_column: text_column })
      end
      RepositoryTextValue.import(repository_text_values, recursive: true, validate: false)
    end
  end

  let!(:repository) { Repository.take }
  let!(:text_column) { repository.repository_columns.find_by(data_type: 'RepositoryTextValue') }
  let!(:user) { repository.created_by }
  let!(:repository_rows) { repository.repository_rows.active }
  let!(:archived_repository_rows) { repository.repository_rows.archived }
  let(:params) {{ page: 1, per_page: 10, search: '' } }
  let(:service) { described_class.new(repository, params, user: user) }

  describe '#call' do
    context 'when view_mode is archived' do
      let(:service) { described_class.new(repository, params, user: user, filter_by_view_mode: true) }

      it 'fetches only archived repository_rows' do
        params[:view_mode] = 'archived'
        repository_rows.limit(10).update_all(archived: true)

        expect(service.call).to all(be_archived)
      end
    end

    context 'when view_mode is active' do
      let(:service) { described_class.new(repository, params, user: user, filter_by_view_mode: true) }

      it 'fetches only active repository_rows' do
        expect(service.call).to all(be_active)
      end

      it 'fetches only active repository_rows within specified time' do
        times = 5.times.map { Benchmark.realtime { service.call } }
        expect(times.min).to be < 0.01
      end
    end

    context 'when ordering param is present' do
      it 'is ordered by row name asc' do
        params[:order] = { column: 'name', dir: 'asc' }
        repository_rows.second.update_column(:name, '0')
        repository_rows = service.call

        expect(repository_rows.first.name).to eq('0')
      end

      it 'is ordered by row name desc' do
        params[:order] = { column: 'name', dir: 'desc' }
        repository_rows.second.update_column(:name, 'ZZZZZ')
        repository_rows = service.call

        expect(repository_rows.first.name).to eq('ZZZZZ')
      end

      context 'when ordering by active_reminders_count' do
        before do
          allow(ApplicationSettings).to receive(:instance)
            .and_return(double(values: { 'stock_management_enabled' => true }))

          stock_column = create(:repository_column, :stock_type, repository: repository, created_by: user)

          create(:repository_stock_value, amount: 0, low_stock_threshold: 5,
                 repository_cell_attributes: { repository_row: repository_rows.first, repository_column: stock_column })
          create(:repository_stock_value, amount: 1000, low_stock_threshold: 5,
                 repository_cell_attributes: { repository_row: repository_rows.second, repository_column: stock_column })
        end

        it 'is ordered by active reminders count desc' do
          params[:order] = { column: 'active_reminders_count', dir: 'desc' }

          expect(service.call.first.id).to eq(repository_rows.first.id)
        end

        it 'is ordered by active reminders count asc' do
          params[:order] = { column: 'active_reminders_count', dir: 'asc' }
          params[:per_page] = repository_rows.count

          expect(service.call.last.id).to eq(repository_rows.first.id)
        end
      end
    end

    context 'when search param is present' do
      it 'filters repository_rows by search param and row name' do
        params[:search] = 'search-item-test'
        repository_rows.second.update_column(:name, 'search-item-test 1')
        repository_rows.third.update_column(:name, 'search-item-test 2')

        service.call.each do |record|
          expect(record.name).to include('search-item-test')
        end
      end

      it 'filters repository_rows by search param and text cell value' do
        params[:search] = 'search-item-test'
        repository_rows.second.repository_text_values.first.update_column(:data, 'search-item-test 1')
        repository_rows.third.repository_text_values.first.update_column(:data, 'search-item-test 2')

        service.call.each do |record|
          expect(record.repository_text_values.first.data).to include('search-item-test')
        end
      end
    end

    context 'when text advanced filter is present' do
      it 'filters repository_rows by row id containing search query' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'row_name',
            operator: 'contains',
            parameters: { text: '1' }
          ]
        }

        service.call.each do |record|
          expect(record.name).to include('1')
        end
      end

      it 'filters repository_rows by row id not containing search query' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'row_name',
            operator: 'doesnt_contain',
            parameters: { text: '1' }
          ]
        }

        service.call.each do |record|
          expect(record.name).not_to include('1')
        end
      end

      it 'filters repository_rows by row name containing search query' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'row_name',
            operator: 'contains',
            parameters: { text: 'search-item-test' }
          ]
        }

        repository_rows.second.update_column(:name, 'search-item-test 1')
        repository_rows.third.update_column(:name, 'search-item-test 2')

        service.call.each do |record|
          expect(record.name).to include('search-item-test')
        end
      end

      it 'filters repository_rows by row name not containing search query' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'row_name',
            operator: 'doesnt_contain',
            parameters: { text: 'search-item-test' }
          ]
        }

        repository_rows.second.update_column(:name, 'search-item-test 1')
        repository_rows.third.update_column(:name, 'search-item-test 2')

        service.call.each do |record|
          expect(record.name).not_to include('search-item-test')
        end
      end
    end

    context 'when added_on advanced filter is present' do
      it 'filters repository_rows created after the specified date' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'added_on',
            operator: 'greater_than',
            parameters: { datetime: 1.day.ago.to_s }
          ]
        }

        repository_rows.second.update_column(:created_at, 2.days.ago)
        repository_rows.third.update_column(:created_at, 3.days.ago)

        expect(service.call.pluck(:created_at)).to all(be > 1.day.ago)
      end

      it 'filters repository_rows created during "today"' do
        params[:advanced_search] = {
          filter_elements: [
            {
              repository_column_id: 'added_on',
              operator: 'today'
            }
          ]
        }

        expect(service.call.pluck(:created_at)).to all(be > DateTime.now.beginning_of_day && be < DateTime.now.end_of_day)
      end

      it 'filters repository_rows created during "yesterday"' do
        previous_day_repository_row = repository_rows.second
        previous_day_repository_row.update_column(:created_at, 1.day.ago)

        params[:advanced_search] = {
          filter_elements: [
            {
              repository_column_id: 'added_on',
              operator: 'yesterday'
            }
          ]
        }

        repository_rows = service.call
        expect(repository_rows).to include(previous_day_repository_row)
        expect(repository_rows.pluck(:created_at)).to all(be > 1.day.ago.beginning_of_day && be < 1.day.ago.end_of_day)
      end

      it 'filters repository_rows created during "last_week"' do
        previous_week_repository_row = repository_rows.second
        previous_week_repository_row.update_column(:created_at, 1.week.ago)

        params[:advanced_search] = {
          filter_elements: [
            {
              repository_column_id: 'added_on',
              operator: 'last_week'
            }
          ]
        }

        repository_rows = service.call
        expect(repository_rows).to include(previous_week_repository_row)
        expect(repository_rows.pluck(:created_at)).to all(be > 1.week.ago.beginning_of_week && be < 1.week.ago.end_of_week)
      end


      it 'filters repository_rows created during "this_month"' do
        previous_month_repository_row = repository_rows.second
        previous_month_repository_row.update_column(:created_at, 1.month.ago)

        params[:advanced_search] = {
          filter_elements: [
            {
              repository_column_id: 'added_on',
              operator: 'this_month'
            }
          ]
        }

        repository_rows = service.call
        expect(repository_rows).not_to include(previous_month_repository_row)
        expect(repository_rows.pluck(:created_at)).to all(be > DateTime.now.beginning_of_month && be < DateTime.now.end_of_month)
      end

      it 'filters repository_rows created during "last_year"' do
        last_year_repository_row = repository_rows.second
        last_year_repository_row.update_column(:created_at, 1.year.ago.end_of_year)

        params[:advanced_search] = {
          filter_elements: [
            {
              repository_column_id: 'added_on',
              operator: 'last_year'
            }
          ]
        }

        repository_rows = service.call
        expect(repository_rows).to include(last_year_repository_row)
        expect(repository_rows.pluck(:created_at)).to all(be < 1.year.ago.end_of_year)
      end

      it 'filters repository_rows created during "this_year"' do
        last_year_repository_row = repository_rows.second
        last_year_repository_row.update_column(:created_at, 1.year.ago.end_of_year)

        params[:advanced_search] = {
          filter_elements: [
            {
              repository_column_id: 'added_on',
              operator: 'this_year'
            }
          ]
        }

        repository_rows = service.call
        expect(repository_rows).to_not include(last_year_repository_row)
        expect(repository_rows.pluck(:created_at)).to all(be > 1.year.ago.end_of_year && be < 1.year.after.beginning_of_year)
      end

      it 'filters repository_rows created between the specified dates' do
        params[:advanced_search] = {
          filter_elements: [
            repository_column_id: 'added_on',
            operator: 'between',
            parameters: { start_datetime: 5.days.ago.to_s, end_datetime: 5.days.after.to_s }
          ]
        }

        repository_rows.second.update_column(:created_at, 20.days.after)
        repository_rows.third.update_column(:created_at, 33.days.ago)

        expect(service.call.pluck(:created_at)).to all(be > 5.days.ago && be < 5.days.after)
      end
    end

    context 'when added_by advanced filter is present' do
      it 'filters repository_rows created by specified user' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'added_by',
            operator: 'any_of',
            parameters: { user_ids: [ user.id ] }
          ]
        }

        expect(service.call.pluck(:created_by_id)).to all(be user.id)
      end

      it 'filters repository_rows not created by specified user' do
        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: 'added_by',
            operator: 'none_of',
            parameters: { user_ids: [ user.id ] }
          ]
        }

        expect(service.call).to be_empty
      end
    end

    context 'when custom text column advanced filter is present' do
      it 'filters repository_rows by specified text value' do
        second_row = repository_rows.second
        third_row = repository_rows.third
        second_row.repository_text_values.take.update_column(:data, 'search-item-test 1')
        third_row.repository_text_values.take.update_column(:data, 'search-item-test 2')

        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: text_column.id,
            operator: 'contains',
            parameters: { text: 'search-item-test' }
          ]
        }

        expect(service.call.pluck(:id)).to match([second_row.id, third_row.id])
      end

      it 'filters repository_rows by not containing specified text value' do
        second_row = repository_rows.second
        third_row = repository_rows.third
        second_row.repository_text_values.take.update_column(:data, 'search-item-test 1')
        third_row.repository_text_values.take.update_column(:data, 'search-item-test 2')

        params[:advanced_search]= {
          filter_elements: [
            repository_column_id: text_column.id,
            operator: 'doesnt_contain',
            parameters: { text: 'search-item-test' }
          ]
        }

        expect(service.call.pluck(:id)).not_to include([second_row.id, third_row.id])
      end
    end
  end
end

RSpec.describe Lists::RepositoryRowsService, 'filters, sorting and extra fields' do
  let(:user) { create :user, full_name: 'admin user' }
  let(:other_user) { create :user, full_name: 'zed other' }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let!(:row_a) { create :repository_row, name: 'A row', repository: repository, created_by: user }
  let!(:row_b) { create :repository_row, name: 'B row', repository: repository, created_by: user }
  let(:base_params) { { page: 1, per_page: 20, search: '' } }

  def call_service(extra = {}, options = {}, target = repository)
    described_class.new(target, base_params.merge(extra).with_indifferent_access, user: user, **options).call.to_a
  end

  def ids_for(extra = {}, options = {}, target = repository)
    call_service(extra, options, target).map(&:id)
  end

  def filter(column_id, operator, parameters = {})
    { advanced_search: { filter_elements: [{ repository_column_id: column_id, operator: operator,
                                              parameters: parameters }] } }
  end

  def fresh_row(row)
    RepositoryRow.find(row.id)
  end

  describe 'fetching' do
    it 'returns filtered count with each record' do
      records = call_service
      expect(records.map(&:id)).to match_array [row_a.id, row_b.id]
      expect(records.map(&:filtered_count).uniq).to eq [2]
    end

    it 'filters by external ids' do
      row_b.update_column(:external_id, 'ext-1')
      expect(ids_for(external_ids: ['ext-1'])).to eq [row_b.id]
    end

    it 'returns nothing when only rows with reminders are requested and none exist' do
      expect(ids_for(only_reminders: true)).to be_empty
    end

    context 'with tasks' do
      let(:project) { create :project, team: team, created_by: user }
      let(:experiment) { create :experiment, project: project, created_by: user }
      let(:my_module) { create :my_module, experiment: experiment, created_by: user }
      let(:my_module_two) { create :my_module, experiment: experiment, created_by: user }

      before do
        create(:mm_repository_row, repository_row: row_a, my_module: my_module, assigned_by: user)
          .update_column(:stock_consumption, 3)
        create :mm_repository_row, repository_row: row_a, my_module: my_module_two, assigned_by: user
      end

      it 'returns only rows assigned to the task' do
        records = call_service({}, { my_module: my_module })
        expect(records.map(&:id)).to eq [row_a.id]
      end

      it 'returns only rows not assigned to the given task' do
        expect(ids_for({}, { unassigned_to_task: my_module })).to eq [row_b.id]
      end

      it 'counts assigned tasks' do
        records = call_service.index_by(&:id)
        expect(records[row_a.id].assigned_my_modules_count).to eq 2
        expect(records[row_b.id].assigned_my_modules_count).to eq 0
      end

      it 'sorts by assigned tasks count' do
        expect(ids_for(order: { column: 'assigned_tasks_count', dir: 'desc' })).to eq [row_a.id, row_b.id]
        expect(ids_for(order: { column: 'assigned_tasks_count', dir: 'asc' })).to eq [row_b.id, row_a.id]
      end

      it 'sorts by consumed stock with and without a task' do
        expect(ids_for({ order: { column: 'consumed_stock', dir: 'desc' } }, { my_module: my_module }))
          .to eq [row_a.id]
        expect(ids_for(order: { column: 'consumed_stock', dir: 'asc' })).to match_array [row_a.id, row_b.id]
      end

      it 'filters by assigned tasks' do
        ids = [my_module.id, my_module_two.id]
        create :mm_repository_row, repository_row: row_b, my_module: my_module, assigned_by: user

        expect(ids_for(filter('assigned', 'any_of', my_module_ids: [my_module_two.id]))).to eq [row_a.id]
        expect(ids_for(filter('assigned', 'none_of', my_module_ids: [my_module_two.id]))).to eq [row_b.id]
        expect(ids_for(filter('assigned', 'all_of', my_module_ids: ids))).to eq [row_a.id]
        expect(ids_for(filter('assigned', 'any_of', my_module_ids: []))).to match_array [row_a.id, row_b.id]
        expect { call_service(filter('assigned', 'wrong', my_module_ids: ids)) }
          .to raise_error(ArgumentError, /Assigned To/)
      end

      context 'when stock management is enabled' do
        before do
          allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(true)
          create :repository_column, :stock_type, repository: repository, created_by: user, name: 'Stock'
        end

        it 'selects consumed stock for the task and the reminders count' do
          record = call_service({}, { my_module: my_module }).first
          expect(record.consumed_stock).to eq 3
          expect(record.active_reminders_count).to eq 0
        end

        it 'sorts by stock column' do
          expect(ids_for(order: { column: 'stock', dir: 'asc' })).to match_array [row_a.id, row_b.id]
        end

        it 'does not look up reminders for archived repositories' do
          repository.update_columns(archived: true, archived_on: Time.zone.now, archived_by_id: user.id)
          expect(call_service.map(&:active_reminders_count)).to all(eq(0))
        end
      end
    end
  end

  describe 'search' do
    let!(:list_column) { create :repository_column, :list_type, repository: repository, created_by: user }
    let!(:list_item) do
      create :repository_list_item, data: 'needle', repository_column: list_column, created_by: user
    end

    before do
      create :repository_list_value, repository_list_item: list_item, created_by: user,
                                     repository_cell_attributes: { repository_row: fresh_row(row_b),
                                                                   repository_column: list_column }
    end

    it 'matches list item values' do
      expect(ids_for(search: 'needle')).to eq [row_b.id]
    end

    it 'filters by list column items' do
      expect(ids_for(filter(list_column.id, 'any_of', item_ids: [list_item.id]))).to eq [row_b.id]
      expect(ids_for(filter(list_column.id, 'none_of', item_ids: [list_item.id]))).to eq [row_a.id]
    end

    it 'raises when list items do not exist' do
      expect { call_service(filter(list_column.id, 'any_of', item_ids: [-1])) }
        .to raise_error(Lists::RepositoryFilters::ValueNotFoundException)
    end

    it 'raises when column does not exist' do
      expect { call_service(filter(-1, 'contains', text: 'x')) }
        .to raise_error(Lists::RepositoryFilters::ColumnNotFoundException)
    end

    it 'sorts by custom column' do
      expect(ids_for(order: { column: "col_#{list_column.id}", dir: 'asc' })).to eq [row_b.id, row_a.id]
      expect(ids_for(order: { column: 'col_999999999', dir: 'asc' })).to match_array [row_a.id, row_b.id]
    end

    it 'sorts by checklist column' do
      checklist_column = create :repository_column, :checklist_type, repository: repository, created_by: user
      expect(ids_for(order: { column: "col_#{checklist_column.id}", dir: 'asc' }))
        .to match_array [row_a.id, row_b.id]
    end
  end

  describe 'predefined filters' do
    it 'filters by row id' do
      expect(ids_for(filter('row_id', 'contains', text: row_a.code))).to eq [row_a.id]
      expect(ids_for(filter('row_id', 'doesnt_contain', text: row_a.code))).to eq [row_b.id]
      expect(ids_for(filter('row_id', 'contains', text: ''))).to match_array [row_a.id, row_b.id]
      expect { call_service(filter('row_id', 'wrong', text: 'IT')) }.to raise_error(ArgumentError, /Row ID/)
    end

    it 'filters by name with blank text and wrong operator' do
      expect(ids_for(filter('row_name', 'contains', text: ''))).to match_array [row_a.id, row_b.id]
      expect { call_service(filter('row_name', 'wrong', text: 'A')) }.to raise_error(ArgumentError, /Name/)
    end

    context 'with relationships' do
      let!(:child_row) { create :repository_row, name: 'Linked child', created_by: user }

      before { create :repository_row_connection, parent: row_a, child: child_row, created_by: user }

      it 'filters by relationships' do
        expect(ids_for(filter('relationships', 'contains', text: 'Linked'))).to eq [row_a.id]
        expect(ids_for(filter('relationships', 'contains_relationship'))).to eq [row_a.id]
        expect(ids_for(filter('relationships', 'doesnt_contain_relationship'))).to eq [row_b.id]
        expect { call_service(filter('relationships', 'wrong')) }.to raise_error(ArgumentError, /Relationship/)
      end

      it 'sorts by connections count' do
        records = call_service(order: { column: 'connections_count', dir: 'desc' })
        expect(records.map(&:id)).to eq [row_a.id, row_b.id]
        expect(records.first.connections_count).to eq 1
      end
    end

    it 'filters by creating, updating and archiving user' do
      row_b.update_columns(created_by_id: other_user.id, last_modified_by_id: other_user.id)

      expect { call_service(filter('added_by', 'wrong')) }.to raise_error(ArgumentError, /Added By/)
      expect(ids_for(filter('updated_by', 'any_of', user_ids: [other_user.id]))).to eq [row_b.id]
      expect(ids_for(filter('updated_by', 'none_of', user_ids: [other_user.id]))).to eq [row_a.id]
      expect { call_service(filter('updated_by', 'wrong')) }.to raise_error(ArgumentError, /Updated By/)

      RepositoryRow.where(id: row_a.id).update_all(archived: true, archived_on: Time.zone.now, archived_by_id: user.id)
      RepositoryRow.where(id: row_b.id)
                   .update_all(archived: true, archived_on: Time.zone.now, archived_by_id: other_user.id)
      archived = { archived: true }
      expect(ids_for(filter('archived_by', 'any_of', user_ids: [other_user.id]).merge(archived))).to eq [row_b.id]
      expect(ids_for(filter('archived_by', 'none_of', user_ids: [other_user.id]).merge(archived))).to eq [row_a.id]
      expect { call_service(filter('archived_by', 'wrong').merge(archived)) }
        .to raise_error(ArgumentError, /Archived By/)
      # archived_by is ignored when not in archived view
      expect(ids_for(filter('archived_by', 'any_of', user_ids: [other_user.id])))
        .to match_array [row_a.id, row_b.id]
    end

    it 'ignores archived_on filter outside archived view' do
      expect(ids_for(filter('archived_on', 'today'))).to match_array [row_a.id, row_b.id]
    end
  end

  describe 'datetime filters' do
    fixed_time = Time.zone.parse('2020-01-15 10:30:00')
    cases = {
      'today' => [-> { Time.zone.now }, -> { 3.days.ago }, {}],
      'yesterday' => [-> { Time.zone.now.beginning_of_day - 12.hours }, -> { Time.zone.now }, {}],
      'last_week' => [-> { Time.zone.now.beginning_of_week - 3.days }, -> { Time.zone.now }, {}],
      'this_month' => [-> { Time.zone.now }, -> { 2.months.ago }, {}],
      'last_year' => [-> { Time.zone.now.beginning_of_year - 1.month }, -> { Time.zone.now }, {}],
      'this_year' => [-> { Time.zone.now }, -> { 2.years.ago }, {}],
      'equal_to' => [-> { fixed_time }, -> { Time.zone.now }, -> { { datetime: fixed_time.iso8601 } }],
      'unequal_to' => [-> { Time.zone.now }, -> { fixed_time }, -> { { datetime: fixed_time.iso8601 } }],
      'greater_than' => [-> { Time.zone.now }, -> { 10.days.ago }, -> { { datetime: 5.days.ago.iso8601 } }],
      'greater_than_or_equal_to' => [-> { Time.zone.now }, -> { 10.days.ago },
                                     -> { { datetime: 5.days.ago.iso8601 } }],
      'less_than' => [-> { 10.days.ago }, -> { Time.zone.now }, -> { { datetime: 5.days.ago.iso8601 } }],
      'less_than_or_equal_to' => [-> { 10.days.ago }, -> { Time.zone.now },
                                  -> { { datetime: 5.days.ago.iso8601 } }],
      'between' => [-> { 10.days.ago }, -> { Time.zone.now },
                    -> { { start_datetime: 15.days.ago.iso8601, end_datetime: 5.days.ago.iso8601 } }]
    }

    { 'added_on' => :created_at, 'updated_on' => :updated_at, 'archived_on' => :archived_on }
      .each do |column_id, attribute|
      context "with #{column_id} filter" do
        let(:extra) { column_id == 'archived_on' ? { archived: true } : {} }

        before do
          if column_id == 'archived_on'
            RepositoryRow.where(id: [row_a.id, row_b.id]).update_all(archived: true, archived_by_id: user.id)
          end
        end

        cases.each do |operator, (matching_time, other_time, parameters)|
          it "applies #{operator} operator" do
            row_a.update_column(attribute, matching_time.call)
            row_b.update_column(attribute, other_time.call)
            params = parameters.is_a?(Proc) ? parameters.call : parameters

            expect(ids_for(filter(column_id, operator, params).merge(extra))).to eq [row_a.id]
          end
        end

        it 'raises on unknown operator' do
          expect { call_service(filter(column_id, 'wrong').merge(extra)) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe 'sorting by default columns' do
    before do
      row_b.update_columns(created_by_id: other_user.id, created_at: 1.day.ago)
    end

    it 'sorts by creator name' do
      expect(ids_for(order: { column: 'created_by', dir: 'desc' })).to eq [row_b.id, row_a.id]
    end

    it 'sorts by creation date' do
      expect(ids_for(order: { column: 'created_at', dir: 'asc' })).to eq [row_b.id, row_a.id]
    end

    it 'sorts by code' do
      expect(ids_for(order: { column: 'code', dir: 'desc' })).to eq [row_b.id, row_a.id]
    end

    it 'ignores unknown sort columns' do
      expect(ids_for(order: { column: 'unknown', dir: 'desc' })).to match_array [row_a.id, row_b.id]
    end
  end

  describe 'snapshots' do
    let(:project) { create :project, team: team, created_by: user }
    let(:experiment) { create :experiment, project: project, created_by: user }
    let(:my_module) { create :my_module, experiment: experiment, created_by: user }
    let(:snapshot) do
      create :repository_snapshot, original_repository: repository, my_module: my_module, created_by: user,
                                   team: team
    end
    let!(:snapshot_row) do
      create :repository_row, name: 'Snapshot row', repository: snapshot, created_by: user, parent_id: row_a.id
    end

    it 'lists snapshot rows without task join and without reminders' do
      allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(true)
      records = call_service({}, { my_module: my_module }, snapshot)

      expect(records.map(&:id)).to eq [snapshot_row.id]
      expect(records.first.active_reminders_count).to eq 0
    end
  end
end
