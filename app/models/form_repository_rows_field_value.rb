# frozen_string_literal: true

class FormRepositoryRowsFieldValue < FormFieldValue
  RELATIONAL_VALUE_INCLUDES = {
    repository_list_value: {
      include: :repository_list_item
    },
    repository_asset_value: {
      include: { asset: { include: { file: { include: :blob } } } }
    },
    repository_status_value: {
      include: :repository_status_item
    },
    repository_checklist_value: {
      include: :repository_checklist_items
    }
  }.freeze

  has_many_attached :snapshot_files

  before_save :attach_snapshot_files

  def attach_snapshot_files
    # find asset values and attach file blobs
    data.map { |r| r['repository_cells'] }.flatten.filter { |c| c['value_type'] == 'RepositoryAssetValue' }.each do |c|
      snapshot_files.attach(ActiveStorage::Blob.find(c.dig('repository_asset_value', 'asset', 'file', 'blob', 'id')))
    end
  end

  def value=(repository_row_ids)
    # removes repository row snapshots if they are not present in the new id array,
    # keeps already existing snapshots intact, and
    # adds new snapshots if not yet present
    self.data ||= []

    # If incoming data is empty, we need to nulify data
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
      reified_repository_cell(row, cell_attributes)
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
      repository_row.as_json(include: { repository_cells: { include: [:repository_column, :value, RELATIONAL_VALUE_INCLUDES] } }).merge(
        {
          'snapshot_at' => DateTime.current,
          'snapshot_by_id' => created_by_id
        }
      )
    end
  end

  def reified_repository_cell(repository_row, cell_attributes)
    repository_cell = repository_row.repository_cells.build(
      cell_attributes.except('value', 'repository_column', *RELATIONAL_VALUE_INCLUDES.keys.map(&:to_s))
    )

    repository_column = RepositoryColumn.new(cell_attributes['repository_column'])
    repository_column.readonly!

    repository_cell.assign_attributes(
      repository_column_id: cell_attributes['repository_column']['id'],
      repository_row_id: repository_row.id,
      repository_column: repository_column,
      value: reified_repository_cell_value(repository_row, cell_attributes)
    )

    repository_cell.readonly!
    repository_cell
  end

  def reified_repository_cell_value(repository_row, cell_attributes)
    cell_value = cell_attributes['repository_column']['data_type'].constantize.new(
      cell_attributes['value'].except('repository_column')
    )

    # mock relational values in-memory
    case cell_value
    when RepositoryAssetValue
      snapshot_file = snapshot_files.find do |f|
        f.blob.id == cell_attributes.dig('repository_asset_value', 'asset', 'file', 'blob', 'id')
      end

      cell_value.asset = Asset.new(
        cell_attributes['repository_asset_value']['asset'].except('file')
      )

      cell_value.asset.file = snapshot_file.blob
      cell_value.asset.readonly!
    when RepositoryListValue
      list_item = RepositoryListItem.new(cell_attributes.dig('repository_list_value', 'repository_list_item'))
      cell_value.repository_list_item = list_item
      list_item.readonly!
      list_item
    when RepositoryStatusValue
      status_item = RepositoryStatusItem.new(cell_attributes.dig('repository_status_value', 'repository_status_item'))
      cell_value.repository_status_item = status_item
      status_item.readonly!
      status_item
    when RepositoryChecklistValue
      cell_value.define_singleton_method(:repository_checklist_items) do
        cell_attributes.dig('repository_checklist_value', 'repository_checklist_items').map do |ci|
          checklist_item = RepositoryChecklistItem.new(ci)
          checklist_item.readonly!
          checklist_item
        end
      end
    when RepositoryStockValue
      # override has_one through association for repository_row to read from memory
      cell_value.define_singleton_method(:repository_row) do
        repository_row
      end
    end

    cell_value.readonly!
    cell_value
  end
end
