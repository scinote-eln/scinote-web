class RepositoryDatatableService

  attr_reader :repository_rows

  def initialize(repository, params, mappings)
    @mappings = mappings
    @repository = repository
    process_query(params)
  end

  private

  def process_query(params)
    contitions = build_conditions(params)
    if contitions[:search_value].present?
      @repository_rows = search(contitions[:search_value])
    else
      @repository_rows = fetch_records
    end
    # byebug
  end

  def fetch_records
    RepositoryRow.preload(:repository_columns,
                          :created_by,
                          repository_cells: :value)
                 .joins(:created_by)
                 .where(repository: @repository)
  end

  def search(value)
    # binding.pry
    filtered_rows = @repository.repository_searchable_rows.where(
      'name ILIKE :value
       OR to_char(created_at, :time) ILIKE :value
       OR user_full_name ILIKE :value
       OR text_value ILIKE :value
       OR date_value ILIKE :value
       OR list_value ILIKE :value',
       value: "%#{value}%",
       time: "DD.MM.YYYY HH24:MI"
    ).pluck(:id)
    fetch_records.where(id: filtered_rows)
  end

  def build_conditions(params)
    search_value = params[:search][:value]
    order_by_column = { column: params[:order][:column].to_i,
                        dir: params[:order][:dir] }
    { search_value: search_value, order_by_column: order_by_column }
  end

  def sortable_columns
    sort_array = [
      'assigned',
      'RepositoryRow.name',
      'RepositoryRow.created_at',
      'User.full_name'
    ]

    sort_array.push(*repository_columns_sort_by)
    @sortable_columns = sort_array
  end

  def repository_columns_sort_by
    array = []
    @repository.repository_columns.count.times do
      array << 'RepositoryCell.value'
    end
    array
  end

end
