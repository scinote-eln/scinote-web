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
      RepositoryImportParser::Importer.new(sheet, mappings, user, repository, true, true, false)
    end

    it 'return a message of imported records' do
      response = subject.run
      expect(response.keys).to include(:status, :total_rows_count, :created_rows_count,
                                       :updated_rows_count, :changes, :import_date)

      expect(response).to include(
        total_rows_count: 5,
        created_rows_count: 5,
        updated_rows_count: 0,
        status: :ok
      )

      expect(response[:changes][:data].count).to eq 5
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

  describe 'with custom sheets' do
    let(:stock_column) { create :repository_column, :stock_type, repository: repository, created_by: user, name: 'Stock' }

    def sheet_for(csv)
      file = Tempfile.new(['import', '.csv'])
      file.write(csv)
      file.rewind
      @tempfiles = (@tempfiles || []) << file
      SpreadsheetParser.open_spreadsheet(file)
    end

    after { (@tempfiles || []).each(&:close!) }

    def importer(csv, mappings, preview: false)
      described_class.new(sheet_for(csv), mappings, user, repository, true, true, preview)
    end

    it 'returns an error when a column is mapped twice' do
      result = importer("Name,A,B\nr1,x,y\n",
                        { '0' => '-1', '1' => custom_column.id.to_s, '2' => custom_column.id.to_s }).run
      expect(result).to include(status: :error, created_rows_count: 0, updated_rows_count: 0, total_rows_count: 1)
      expect(repository.repository_rows.count).to eq 0
    end

    it 'ignores unmapped (do_not_import) columns and blank rows' do
      result = importer("Name,A,B\nr1,x,y\n,,\nr2,z,w\n",
                        { '0' => '-1', '1' => 'do_not_import', '2' => custom_column.id.to_s }).run
      expect(result).to include(status: :ok, created_rows_count: 2)
      expect(repository.repository_rows.pluck(:name)).to match_array(%w(r1 r2))
      expect(RepositoryTextValue.pluck(:data)).to match_array(%w(y w))
    end

    it 'updates existing rows matched by item id and counts them as updated' do
      row = create :repository_row, repository: repository, created_by: user, name: 'old'
      result = importer("ID,Name,Custom\n#{RepositoryRow::ID_PREFIX}#{row.id},new name,hello\n",
                        { '0' => '0', '1' => '-1', '2' => custom_column.id.to_s }).run
      expect(result).to include(status: :ok, created_rows_count: 0, updated_rows_count: 1)
      expect(row.reload.name).to eq 'new name'
      expect(row.repository_cells.find_by(repository_column: custom_column).value.data).to eq 'hello'
    end

    it 'updates an existing cell value' do
      row = create :repository_row, repository: repository, created_by: user, name: 'keep'
      cell = RepositoryCell.create!(repository_row: row, repository_column: custom_column,
                                    value: RepositoryTextValue.new(data: 'before', created_by: user,
                                                                   last_modified_by: user))
      importer("ID,Name,Custom\n#{RepositoryRow::ID_PREFIX}#{row.id},keep,after\n",
               { '0' => '0', '1' => '-1', '2' => custom_column.id.to_s }).run
      expect(cell.reload.value.data).to eq 'after'
    end

    it 'erases an existing cell when the incoming cell is empty' do
      row = create :repository_row, repository: repository, created_by: user, name: 'keep'
      cell = RepositoryCell.create!(repository_row: row, repository_column: custom_column,
                                    value: RepositoryTextValue.new(data: 'before', created_by: user,
                                                                   last_modified_by: user))
      importer("ID,Name,Custom\n#{RepositoryRow::ID_PREFIX}#{row.id},keep,\n",
               { '0' => '0', '1' => '-1', '2' => custom_column.id.to_s }).run
      expect(RepositoryCell.exists?(cell.id)).to be false
    end

    it 'skips archived rows' do
      row = create :repository_row, :archived, repository: repository, created_by: user, name: 'archived'
      result = importer("ID,Name\n#{RepositoryRow::ID_PREFIX}#{row.id},changed\n", { '0' => '0', '1' => '-1' }).run
      expect(result).to include(created_rows_count: 0, updated_rows_count: 0)
      expect(row.reload.name).to eq 'archived'
    end

    it 'does not create rows for unknown ids' do
      result = importer("ID,Name\n#{RepositoryRow::ID_PREFIX}999999,ghost\n", { '0' => '0', '1' => '-1' }).run
      expect(result).to include(status: :ok, created_rows_count: 0, updated_rows_count: 0)
      expect(repository.repository_rows.count).to eq 0
    end

    it 'reports unknown ids as invalid in preview' do
      result = importer("ID,Name\n#{RepositoryRow::ID_PREFIX}999999,ghost\n", { '0' => '0', '1' => '-1' },
                        preview: true).run
      statuses = result[:changes][:data].map { |r| r[:attributes][:import_status] }
      expect(statuses).to eq ['invalid']
    end

    it 'does not persist anything in preview but reports created rows' do
      result = importer("Name,Custom\nr1,x\nr2,y\n", { '0' => '-1', '1' => custom_column.id.to_s },
                        preview: true).run
      expect(result).to include(status: :ok, created_rows_count: 2, total_rows_count: 2)
      expect(repository.repository_rows.count).to eq 0
      expect(result[:changes][:data].size).to eq 2
    end

    it 'flags incorrectly formatted values as invalid in preview' do
      number = create :repository_column, repository: repository, created_by: user, name: 'Amount',
                                          data_type: 'RepositoryNumberValue'
      result = importer("Name,Amount\nr1,not-a-number\n", { '0' => '-1', '1' => number.id.to_s },
                        preview: true).run
      row = result[:changes][:data].first
      expect(row[:attributes][:import_status]).to eq 'invalid'
      expect(row[:attributes][:import_message]).to be_present
      expect(result[:created_rows_count]).to eq 0
    end

    it 'rolls the row back for incorrectly formatted values on a real import' do
      number = create :repository_column, repository: repository, created_by: user, name: 'Amount',
                                          data_type: 'RepositoryNumberValue'
      result = importer("Name,Amount\nr1,not-a-number\n", { '0' => '-1', '1' => number.id.to_s }).run
      expect(result[:created_rows_count]).to eq 0
      expect(repository.repository_rows.count).to eq 0
    end

    it 'imports numbers' do
      number = create :repository_column, repository: repository, created_by: user, name: 'Amount',
                                          data_type: 'RepositoryNumberValue'
      importer("Name,Amount\nr1,12.5\n", { '0' => '-1', '1' => number.id.to_s }).run
      row = repository.repository_rows.find_by(name: 'r1')
      expect(row.repository_cells.find_by(repository_column: number).value.data).to eq BigDecimal('12.5')
    end

    it 'imports stock values with units and updates them on a second import' do
      stock_column
      importer("Name,Stock\nr1,5 ml\n", { '0' => '-1', '1' => stock_column.id.to_s }).run
      row = repository.repository_rows.find_by(name: 'r1')
      value = row.repository_cells.find_by(repository_column: stock_column).value
      expect(value.amount).to eq 5
      expect(value.repository_stock_unit_item.data).to eq 'ml'

      importer("ID,Name,Stock\n#{RepositoryRow::ID_PREFIX}#{row.id},r1,8 ml\n",
               { '0' => '0', '1' => '-1', '2' => stock_column.id.to_s }).run
      expect(value.reload.amount).to eq 8
    end

    it 'zeroes an existing stock value when the incoming cell is empty' do
      stock_column
      importer("Name,Stock\nr1,5 ml\n", { '0' => '-1', '1' => stock_column.id.to_s }).run
      row = repository.repository_rows.find_by(name: 'r1')
      importer("ID,Name,Stock\n#{RepositoryRow::ID_PREFIX}#{row.id},r1,\n",
               { '0' => '0', '1' => '-1', '2' => stock_column.id.to_s }).run
      expect(row.repository_cells.find_by(repository_column: stock_column).value.amount).to eq 0
    end

    it 'updates an existing list cell to a new item' do
      importer("Name,Group\nr1,a\n", { '0' => '-1', '1' => sample_group_column.id.to_s }).run
      row = repository.repository_rows.find_by(name: 'r1')
      importer("ID,Name,Group\n#{RepositoryRow::ID_PREFIX}#{row.id},r1,b\n",
               { '0' => '0', '1' => '-1', '2' => sample_group_column.id.to_s }).run
      expect(row.repository_cells.find_by(repository_column: sample_group_column).value.formatted).to eq 'b'
    end
  end
end
