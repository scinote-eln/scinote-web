# frozen_string_literal: true

class LinkedRepository < Repository
  def default_table_state
    state = Constants::REPOSITORY_TABLE_DEFAULT_STATE.deep_dup
    state['order'] = [[3, 'asc']]
    state['ColReorder'] << state['ColReorder'].length
    state['columns'].insert(1, Constants::REPOSITORY_TABLE_STATE_CUSTOM_COLUMN_TEMPLATE)
    state
  end
end
