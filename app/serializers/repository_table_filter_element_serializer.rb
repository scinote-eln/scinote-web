# frozen_string_literal: true

class RepositoryTableFilterElementSerializer < ActiveModel::Serializer
  attributes :repository_column_id, :operator, :parameters
end
