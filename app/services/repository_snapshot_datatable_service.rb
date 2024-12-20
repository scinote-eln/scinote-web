# frozen_string_literal: true

class RepositorySnapshotDatatableService < RepositoryDatatableService
  private

  def create_columns_mappings
    index = @repository.default_columns_count
    @mappings = {}
    @repository.repository_columns.order(:parent_id).each do |column|
      @mappings[column.id] = index.to_s
      index += 1
    end
  end

  def process_query
    search_value = @params[:search][:value]
    order_params = @params[:order].first
    order_by_column = { column: order_params[:column].to_i, dir: order_params[:dir] }

    repository_rows = fetch_rows(search_value).preload(Extends::REPOSITORY_ROWS_PRELOAD_RELATIONS)
    repository_rows = repository_rows.preload(:repository_columns, repository_cells: { value: @repository.cell_preload_includes }) if @preload_cells
    repository_rows = repository_rows.preload(:repository_stock_cell, :repository_stock_value) if @repository.has_stock_management?
    # don't load reminders for snapshots
    repository_rows = repository_rows.select('FALSE AS has_active_reminders') if Repository.reminders_enabled?

    sort_rows(order_by_column, repository_rows)
  end

  def fetch_rows(search_value)
    repository_rows = @repository.repository_rows

    @all_count = repository_rows.count

    if search_value.present?
      repository_rows = repository_rows.joins(:created_by)
      repository_row_matches = repository_rows.where_attributes_like(@repository.default_search_fileds, search_value)
      results = repository_rows.where(id: repository_row_matches)

      data_types = @repository.repository_columns.pluck(:data_type).uniq

      Extends::REPOSITORY_EXTRA_SEARCH_ATTR.each do |data_type, config|
        next unless data_types.include?(data_type.to_s)

        custom_cell_matches = repository_rows.joins(config[:includes])
                                             .where_attributes_like(config[:field], search_value)
        results = results.or(repository_rows.where(id: custom_cell_matches))
      end

      @filtered_count = results.count
      repository_rows = results
    else
      @filtered_count = @all_count
    end

    repository_rows.joins('LEFT OUTER JOIN "users" "created_by" ON "created_by"."id" = "repository_rows"."created_by_id"')
                   .select('repository_rows.*')
                   .select('MAX("created_by"."full_name") AS created_by_full_name')
                   .select('COUNT("repository_rows"."id") OVER() AS filtered_count')
                   .group('repository_rows.id')
  end

  def build_sortable_columns
    array = [
      'repository_rows.parent_id',
      'repository_rows.name',
      'repository_rows.created_at',
      'users.full_name'
    ]
    @repository.repository_columns.count.times do
      array << 'repository_cell.value'
    end
    array
  end
end
