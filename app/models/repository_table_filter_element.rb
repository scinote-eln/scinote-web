# frozen_string_literal: true

class RepositoryTableFilterElement < ApplicationRecord
  attr_accessor :skip_items_validation

  enum operator: { contains: 0,
                   doesnt_contain: 1,
                   empty: 2,
                   any_of: 3,
                   none_of: 4,
                   all_of: 5,
                   equal_to: 6,
                   unequal_to: 7,
                   greater_than: 8,
                   less_than: 9,
                   greater_than_or_equal_to: 10,
                   less_than_or_equal_to: 11,
                   between: 12,
                   file_attached: 13,
                   file_not_attached: 14,
                   file_contains: 15,
                   today: 16,
                   yesterday: 17,
                   last_week: 18,
                   this_month: 19,
                   last_year: 20,
                   this_year: 21 }

  belongs_to :repository_table_filter, inverse_of: :repository_table_filter_elements
  belongs_to :repository_column, inverse_of: :repository_table_filter_elements

  validates :repository_column, presence: true,
                                inclusion: { in: proc { |record|
                                                   record.repository_table_filter.repository.repository_columns
                                                 } }

  validate :items_exist

  after_validation :push_errors_to_filter

  private

  def items_exist
    return if skip_items_validation

    error = false
    case repository_column&.data_type
    when 'RepositoryChecklistValue'
      items = repository_column.repository_checklist_items.where(id: parameters['item_ids'])
      error = items.size != parameters['item_ids'].length
    when 'RepositoryListValue'
      items = repository_column.repository_list_items.where(id: parameters['item_ids'])
      error = items.size != parameters['item_ids'].length
    when 'RepositoryStatusValue'
      items = repository_column.repository_status_items.where(id: parameters['item_ids'])
      error = items.size != parameters['item_ids'].length
    end

    if error
      msg = I18n.t('activerecord.errors.models.repository_table_filter_element.attributes.parameters.must_be_valid')
      errors.add(:column_items, msg)
    end
  end

  def push_errors_to_filter
    errors.each do |e|
      repository_table_filter.errors.add(e.attribute, e.message)
    end
  end
end
