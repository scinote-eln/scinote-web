# frozen_string_literal: true

module RepositoryColumnsHelper
  def defined_delimiters_options
    (%i(auto) + Constants::REPOSITORY_LIST_ITEMS_DELIMITERS_MAP.keys)
      .map { |e| Hash[t('libraries.manange_modal_column.list_type.delimiters.' + e.to_s), e] }
      .inject(:merge)
  end

  def repository_columns_ordered_by_state(repository_row)
    repository = repository_row.repository
    columns = repository.repository_columns.order(:id).to_a
    return columns if columns.blank?

    columns_by_id = columns.index_by(&:id)
    stock_column = columns.find { |column| column.data_type == 'RepositoryStockValue' }

    view_mode = repository_row.archived? ? 'archived' : 'active'
    table_state = current_user.user_settings.find_by(key: "repository_table_#{repository.id}_#{view_mode}_table_state")
    columns_state = table_state&.value&.dig('columnsState')
    return columns if columns_state.blank?

    ordered_columns = columns_state.filter_map do |column_state|
      col_id = column_state['colId']
      if col_id == 'stock'
        stock_column
      elsif col_id =~ /\Acol_(\d+)\z/
        columns_by_id[Regexp.last_match(1).to_i]
      end
    end

    ordered_columns | columns
  end
end
