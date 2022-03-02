# frozen_string_literal: true

class RepositoryTableFilterSerializer < ActiveModel::Serializer
  attributes :name, :default_columns
  has_many :repository_table_filter_elements, serializer: RepositoryTableFilterElementSerializer
end
