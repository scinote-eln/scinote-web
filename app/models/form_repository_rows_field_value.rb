# frozen_string_literal: true

class FormRepositoryRowsFieldValue < FormFieldValue
  def value=(repository_row_ids)
    # removes repository row snapshots if they are not present in the new id array,
    # keeps already existing snapshots intact, and
    # adds new snapshots if not yet present
    self.data ||= []

    # If income data is empty, we need nulify data
    if repository_row_ids.blank?
      self.data = nil
      return
    end

    removed_repository_row_ids = data.pluck('id') - repository_row_ids
    existing_repository_row_ids = data.pluck('id') & repository_row_ids

    self.data =
      data.filter { |r| removed_repository_row_ids.exclude?(r['id']) } +
      repository_row_snapshots(repository_row_ids - existing_repository_row_ids)
  end

  def value
    data
  end

  def reified_repository_row_by_id(repository_row_id)
    # build an in-memory, read-only representation of the repository row in the snapshot

    row_attributes = data.find { |r| r['id'] == repository_row_id.to_i }
    row = RepositoryRow.new(row_attributes.except('repository_cells'))

    row.repository_cells = row_attributes['repository_cells'].map do |cell_attributes|
      repository_cell = row.repository_cells.build(cell_attributes.except('value', 'repository_column'))
      repository_column = RepositoryColumn.new(cell_attributes['repository_column'])
      repository_column.readonly!

      repository_cell.assign_attributes(
        repository_column_id: cell_attributes['repository_column']['id'],
        repository_row_id: repository_row_id.to_i,
        repository_column: repository_column,
        value:
          cell_attributes['repository_column']['data_type'].constantize.new(
            cell_attributes['value'].except('repository_column')
          )
      )
      repository_cell.readonly!
      repository_cell
    end

    row.snapshot_by_name = User.find_by(id: row.snapshot_by_id)&.full_name
    row.readonly!
    row
  end

  def formatted
    value&.map { |i| "#{i['name']} (#{RepositoryRow::ID_PREFIX}#{i['id']})" }&.join(' | ')
  end

  private

  def repository_row_snapshots(repository_row_ids)
    RepositoryRow.includes(repository_cells: %i(repository_column value)).where(id: repository_row_ids).map do |repository_row|
      repository_row.as_json(include: { repository_cells: { include: %i(repository_column value) } }).merge(
        {
          'snapshot_at' => DateTime.current,
          'snapshot_by_id' => created_by_id
        }
      )
    end
  end
end
