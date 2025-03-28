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

  def formatted
    value&.map { |i| "#{i['name']} (IT#{i['id']})" }&.join(' | ')
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
