# frozen_string_literal: true

class BmtRepository < LinkedRepository
  before_create :enforce_singleton

  def default_table_state
    state = Constants::REPOSITORY_TABLE_DEFAULT_STATE.deep_dup
    state['ColReorder'] << state['ColReorder'].length
    state['columns'].insert(1, Constants::REPOSITORY_TABLE_STATE_CUSTOM_COLUMN_TEMPLATE)
    state['order'] = [[3, 'asc']]
    state
  end

  def default_sortable_columns
    [
      'assigned',
      'users.full_name',
      'repository_rows.external_id',
      'repository_rows.id',
      'repository_rows.name',
      'repository_rows.created_at'
    ]
  end

  private

  def enforce_singleton
    raise ActiveRecord::RecordNotSaved, I18n.t('repositories.bmt_singleton_error') if self.class.any?
  end
end
