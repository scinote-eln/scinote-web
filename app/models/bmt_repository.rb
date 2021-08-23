# frozen_string_literal: true

class BmtRepository < LinkedRepository
  before_create :enforce_singleton

  def default_sortable_columns
    [
      'assigned',
      'repository_rows.external_id',
      'repository_rows.id',
      'repository_rows.name',
      'repository_rows.created_at'
    ]
  end

  def default_search_fileds
    super - ['users.full_name']
  end

  private

  def enforce_singleton
    raise ActiveRecord::RecordNotSaved, I18n.t('repositories.bmt_singleton_error') if self.class.any?
  end
end
