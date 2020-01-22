# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDatatableService do
  let!(:team) { create :team }
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
           repository: repository,
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

  context 'object' do
    let(:params) do
      { order: { 0 => { column: '3', dir: 'asc' } },
        search: { value: 'row' } }
    end

    let(:subject) do
      RepositoryDatatableService.new(repository, params, user)
    end

    describe '#build_conditions/1' do
      it 'parsers the contitions' do
        contitions = subject.send(:build_conditions, params)
        expect(contitions[:search_value]).to eq 'row'
        expect(contitions[:order_by_column]).to eq(
          column: 3, dir: 'asc'
        )
      end
    end
  end

  describe 'ordering' do
    it 'is ordered by row name asc' do
      params = { order: { 0 => { column: '3', dir: 'asc' } },
                 search: { value: '' } }
      subject = RepositoryDatatableService.new(repository,
                                               params,
                                               user)
      expect(subject.repository_rows.first.name).to eq 'A row'
      expect(subject.repository_rows.last.name).to eq 'B row'
    end

    it 'is ordered by row name desc' do
      params = { order: { 0 => { column: '3', dir: 'desc' } },
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
      params = { order: { 0 => { column: '4', dir: 'desc' } },
                 search: { value: 'test' } }
      subject = RepositoryDatatableService.new(repository,
                                               params,
                                               user)
      expect(subject.repository_rows.first.name).to eq 'test'
      expect(subject.repository_rows.length).to eq 1
    end
  end
end
