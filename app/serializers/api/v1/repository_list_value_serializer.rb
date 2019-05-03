# frozen_string_literal: true

module Api
  module V1
    class RepositoryListValueSerializer < ActiveModel::Serializer
      attribute :repository_list_item_id, key: :inventory_list_item_id
      attribute :formatted, key: :inventory_list_item_name
    end
  end
end
