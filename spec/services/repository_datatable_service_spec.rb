# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDatatableService do
  let!(:team) { create :team, created_by: user }
  let!(:user) { create :user, email: 'user_one@asdf.com' }
  let!(:repository) do
    create :repository, name: 'my repo',
                        created_by: user,
                        team: team
  end
  let!(:repository_column) do
    create :repository_column,
           name: 'My column',
           data_type: :RepositoryListValue,
           repository: repository
  end
  let!(:repository_state) do
    RepositoryTableStateService.new(user, repository).create_default_state
  end
  let!(:repository_row) do
    create :repository_row, name: 'A row',
                            repository: repository,
                            created_by: user,
                            last_modified_by: user
  end
  let!(:repository_row_two) do
    create :repository_row, name: 'B row',
                            repository: repository,
                            created_by: user,
                            last_modified_by: user
  end
  let!(:list_item) do
    create :repository_list_item,
           data: 'bug',
           repository_column: repository_column,
           created_by: user,
           last_modified_by: user
  end
  let!(:repository_list_value) do
    create :repository_list_value,
           repository_list_item: list_item,
           created_by: user,
           last_modified_by: user,
           repository_cell_attributes: {
             repository_column: repository_column,
             repository_row: repository_row
           }
  end

  describe 'ordering' do
    it 'is ordered by row name asc' do
      params = { order:[{ column: '3', dir: 'asc' }],
                 search: { value: '' } }
      subject = RepositoryDatatableService.new(repository,
                                               params,
                                               user)
      expect(subject.repository_rows.first.name).to eq 'A row'
      expect(subject.repository_rows.last.name).to eq 'B row'
    end

    it 'is ordered by row name desc' do
      params = { order: [{ column: '3', dir: 'desc' }],
                 search: { value: '' } }
      subject = RepositoryDatatableService.new(repository,
                                               params,
                                               user)
      expect(subject.repository_rows.first.name).to eq 'B row'
      expect(subject.repository_rows.last.name).to eq 'A row'
    end
  end

  describe 'search' do
    before do
      create :repository_row, name: 'test',
                              repository: repository,
                              created_by: user,
                              last_modified_by: user
    end

    it 'returns only the searched entity' do
      params = { order: [{ column: '4', dir: 'desc' }],
                 search: { value: 'test' } }
      subject = RepositoryDatatableService.new(repository,
                                               params,
                                               user)
      expect(subject.repository_rows.first.name).to eq 'test'
      expect(subject.repository_rows.length).to eq 1
    end

    context 'when using advanced filter time presets' do
      let(:base_params) do
        { order: [{ column: '4', dir: 'desc' }], search: { value: '' } }
      end
      it 'returns the rows matching "today"' do
        repository_row.update_column(:created_at, 2.days.ago)
        today_repository_row = RepositoryRow.create(
          name: "Today",
          repository: repository,
          created_by: user,
          last_modified_by: user
        )

        params = base_params.merge(
          advanced_search: {
            filter_elements: [{repository_column_id: "added_on", operator: "today"}]
          }
        )

        repository_rows = RepositoryDatatableService.new(repository, params, user).repository_rows
        expect(repository_rows).to include(today_repository_row)
        expect(repository_rows).to_not include(repository_row)
      end

      it 'returns the rows matching "yesterday"' do
        yesterday_repository_row = RepositoryRow.create(
          name: "Yesterday",
          repository: repository,
          created_by: user,
          last_modified_by: user
        )

        yesterday_repository_row.update_column(:created_at, 1.day.ago)

        params = base_params.merge(
          advanced_search: {
            filter_elements: [{repository_column_id: "added_on", operator: "yesterday"}]
          }
        )

        repository_rows = RepositoryDatatableService.new(repository, params, user).repository_rows
        expect(repository_rows).to include(yesterday_repository_row)
        expect(repository_rows).to_not include(repository_row)
      end

      it 'returns the rows matching "last_week"' do
        last_week_repository_row = RepositoryRow.create(
          name: "Last week",
          repository: repository,
          created_by: user,
          last_modified_by: user
        )

        last_week_repository_row.update_column(:created_at, 1.week.ago)

        params = base_params.merge(
          advanced_search: {
            filter_elements: [{repository_column_id: "added_on", operator: "last_week"}]
          }
        )

        repository_rows = RepositoryDatatableService.new(repository, params, user).repository_rows
        expect(repository_rows).to include(last_week_repository_row)
        expect(repository_rows).to_not include(repository_row)
      end

      it 'returns the rows matching "this_month"' do
        repository_row.update_column(:created_at, Time.now)
        previous_month_repository_row = RepositoryRow.create(
          name: "Last week",
          repository: repository,
          created_by: user,
          last_modified_by: user
        )

        previous_month_repository_row.update_column(:created_at, 1.month.ago)

        params = base_params.merge(
          advanced_search: {
            filter_elements: [{repository_column_id: "added_on", operator: "this_month"}]
          }
        )

        repository_rows = RepositoryDatatableService.new(repository, params, user).repository_rows
        expect(repository_rows).to include(repository_row)
        expect(repository_rows).to_not include(previous_month_repository_row)
      end

      it 'returns the rows matching "last_year"' do
        last_year_repository_row = RepositoryRow.create(
          name: "Yesterday",
          repository: repository,
          created_by: user,
          last_modified_by: user
        )

        last_year_repository_row.update_column(:created_at, 1.year.ago)

        params = base_params.merge(
          advanced_search: {
            filter_elements: [{repository_column_id: "added_on", operator: "last_year"}]
          }
        )

        repository_rows = RepositoryDatatableService.new(repository, params, user).repository_rows
        expect(repository_rows).to include(last_year_repository_row)
        expect(repository_rows).to_not include(repository_row)
      end

      it 'returns the rows matching "this_year"' do
        last_year_repository_row = RepositoryRow.create(
          name: "Yesterday",
          repository: repository,
          created_by: user,
          last_modified_by: user
        )

        last_year_repository_row.update_column(:created_at, 1.year.ago.end_of_year)

        params = base_params.merge(
          advanced_search: {
            filter_elements: [{repository_column_id: "added_on", operator: "this_year"}]
          }
        )

        repository_rows = RepositoryDatatableService.new(repository, params, user).repository_rows
        expect(repository_rows).to_not include(last_year_repository_row)
        expect(repository_rows).to include(repository_row)
      end
    end
  end
end
