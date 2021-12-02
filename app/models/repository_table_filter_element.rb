# frozen_string_literal: true

class RepositoryTableFilterElement < ApplicationRecord
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
                   file_is_attached: 13,
                   file_is_not_attached: 14,
                   file_contains: 15 }

  belongs_to :repository_table_filter, inverse_of: :repository_table_filter_elements
  belongs_to :repository_column, inverse_of: :repository_table_filter_elements

  validates :repository_column, presence: true,
                                inclusion: { in: proc { |record|
                                                   record.repository_table_filter.repository.repository_columns
                                                 } }
end
