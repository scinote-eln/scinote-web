# frozen_string_literal: true

class LinkedRepository < Repository
  def default_table_state
    state = Constants::REPOSITORY_TABLE_DEFAULT_STATE.deep_dup
    state['order'] = [[3, 'asc']]
    state['ColReorder'] << state['ColReorder'].length
    state['columns'].insert(1, Constants::REPOSITORY_TABLE_STATE_CUSTOM_COLUMN_TEMPLATE)
    state
  end

  def default_sortable_columns
    [
      'assigned',
      'repository_rows.external_id',
      'repository_rows.id',
      'repository_rows.name',
      'repository_rows.created_at',
      'users.full_name',
      'repository_rows.archived_on',
      'archived_bies_repository_rows.full_name'
    ]
  end

  def default_search_fileds
    super << 'repository_rows.external_id'
  end
end
