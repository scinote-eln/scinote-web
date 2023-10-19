# frozen_string_literal: true

module RepositoryColumnsHelper
  def defined_delimiters_options
    (%i(auto) + Constants::REPOSITORY_LIST_ITEMS_DELIMITERS_MAP.keys)
      .map { |e| Hash[t('libraries.manange_modal_column.list_type.delimiters.' + e.to_s), e] }
      .inject(:merge)
  end

  def repository_columns_ordered_by_state(repository)
    columns = repository.repository_columns.order(:id).to_a
    return columns if columns.blank?

    table_state = current_user.repository_table_states.find_by(repository: repository)
    return columns unless table_state && table_state.state['ColReorder'].present?

    default_columns_count = repository.default_table_state['ColReorder'].length
    columns_reorder = table_state.state['ColReorder'] - repository.default_table_state['ColReorder']
    return columns if columns_reorder.blank?

    columns_reorder.map! { |position| position - default_columns_count }
    reordered_columns = []

    columns_reorder.each do |position|
      column = columns.at(position)
      reordered_columns << column if column.present?
    end
    reordered_columns | columns
  end
end
