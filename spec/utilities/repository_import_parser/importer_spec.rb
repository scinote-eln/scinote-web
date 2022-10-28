require 'rails_helper'

describe RepositoryImportParser::Importer do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:repository) { create :repository, team: team, created_by: user }
  let!(:sample_group_column) do
    create :repository_column, repository: repository,
                               created_by: user,
                               name: 'Sample group',
                               data_type: 'RepositoryListValue'
  end
  let!(:sample_type_column) do
    create :repository_column, repository: repository,
                               created_by: user,
                               name: 'Sample type',
                               data_type: 'RepositoryListValue'
  end
  let!(:custom_column) do
    create :repository_column, repository: repository,
                               created_by: user,
                               name: 'Custom items',
                               data_type: 'RepositoryTextValue'
  end

  let(:sheet) do
    SpreadsheetParser.open_spreadsheet(file_fixture('export.csv').open)
  end
  let(:mappings) do
    { '0' => '-1',
      '1' => '',
      '2' => '',
      '3' => sample_group_column.id.to_s,
      '4' => sample_type_column.id.to_s,
      '5' => custom_column.id.to_s }
  end

  describe '#run/0' do
    let(:subject) do
      RepositoryImportParser::Importer.new(sheet, mappings, user, repository)
    end

    it 'return a message of imported records' do
      expect(subject.run).to eq({ status: :ok, nr_of_added: 5, total_nr: 5 })
    end

    it 'generate 5 new repository rows' do
      subject.run
      expect(repository.repository_rows.count).to eq 5
    end

    it 'generate 3 new repository list items on Sample group column' do
      subject.run
      column = repository.repository_columns.find_by_name('Sample group')
      expect(column.repository_list_items.count).to eq 3
      column.repository_list_items.each do |repository_item|
        expect(['group 1', 'group 2', 'group 3']).to include(repository_item.data)
      end
    end

    it 'generate 2 new repository list items on Sample type column' do
      subject.run
      column = repository.repository_columns.find_by_name('Sample type')
      expect(column.repository_list_items.count).to eq 2
      column.repository_list_items.each do |repository_item|
        expect(['type 1', 'type 2']).to include(repository_item.data)
      end
    end

    it 'assign custom columns to imported repository row' do
      subject.run
      row = repository.repository_rows.find_by_name('Sample 1')
      sample_group_cell = row.repository_cells
                             .find_by_repository_column_id(
                               sample_group_column.id
                             )
      sample_type_cell = row.repository_cells
                            .find_by_repository_column_id(
                              sample_type_column.id
                            )
      custom_column_cell = row.repository_cells
                              .find_by_repository_column_id(
                                custom_column.id
                              )
      expect(sample_group_cell.value.formatted).to eq 'group 1'
      expect(sample_type_cell.value.formatted).to eq 'type 2'
      expect(custom_column_cell.value.formatted).to eq 'test test'
    end
  end
end
