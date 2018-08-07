# frozen_string_literal: true

module Api
  module V1
    class RepositoryListValueSerializer < ActiveModel::Serializer
      attribute :formatted, key: :value
      attribute :repository_list_item_id, key: :list_item_id
    end
  end
end
