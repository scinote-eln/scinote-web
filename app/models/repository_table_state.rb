# frozen_string_literal: true

class RepositoryTableState < ApplicationRecord
  belongs_to :user, inverse_of: :repository_table_states
  belongs_to :repository, class_name: 'RepositoryBase', inverse_of: :repository_table_states
end
