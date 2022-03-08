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
<<<<<<< HEAD
    search_value = @params[:search][:value]
    order_params = @params[:order].first
    order_by_column = { column: order_params[:column].to_i, dir: order_params[:dir] }

    repository_rows = fetch_rows(search_value).preload(Extends::REPOSITORY_ROWS_PRELOAD_RELATIONS)

    sort_rows(order_by_column, repository_rows)
=======
    search_value = build_conditions(@params)[:search_value]
    order_obj = build_conditions(@params)[:order_by_column]

    repository_rows = fetch_rows(search_value)

    repository_rows = repository_rows.preload(Extends::REPOSITORY_ROWS_PRELOAD_RELATIONS)

    @repository_rows = sort_rows(order_obj, repository_rows)
>>>>>>> Pulled latest release
  end

  def fetch_rows(search_value)
    repository_rows = @repository.repository_rows

    @all_count = repository_rows.count

    if search_value.present?
<<<<<<< HEAD
      repository_row_matches = repository_rows.where_attributes_like(@repository.default_search_fileds, search_value)
      results = repository_rows.where(id: repository_row_matches)

      data_types = @repository.repository_columns.pluck(:data_type).uniq

      Extends::REPOSITORY_EXTRA_SEARCH_ATTR.each do |data_type, config|
        next unless data_types.include?(data_type.to_s)

        custom_cell_matches = repository_rows.joins(config[:includes])
                                             .where_attributes_like(config[:field], search_value)
=======
      matched_by_user = repository_rows.joins(:created_by).where_attributes_like('users.full_name', search_value)

      repository_row_matches = repository_rows
                               .where_attributes_like(['repository_rows.name', 'repository_rows.id'], search_value)
      results = repository_rows.where(id: repository_row_matches)
      results = results.or(repository_rows.where(id: matched_by_user))

<<<<<<< HEAD
      Extends::REPOSITORY_EXTRA_SEARCH_ATTR.each do |field, include_hash|
        custom_cell_matches = repository_rows.joins(repository_cells: include_hash)
                                             .where_attributes_like(field, search_value)
>>>>>>> Pulled latest release
=======
      data_types = @repository.repository_columns.pluck(:data_type).uniq

      Extends::REPOSITORY_EXTRA_SEARCH_ATTR.each do |data_type, config|
        next unless data_types.include?(data_type.to_s)

        custom_cell_matches = repository_rows.joins(config[:includes])
                                             .where_attributes_like(config[:field], search_value)
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
        results = results.or(repository_rows.where(id: custom_cell_matches))
      end

      repository_rows = results
    end

    repository_rows.left_outer_joins(:created_by)
                   .select('repository_rows.*')
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
