# frozen_string_literal: true

module Api
  module V1
    class ProtocolSerializer < ActiveModel::Serializer
      type :protocols
      attributes :id, :name, :authors, :description, :added_by_id,
                 :my_module_id, :team_id, :protocol_type, :parent_id,
                 :parent_updated_at, :archived_by_id, :archived_on,
                 :restored_by_id, :restored_on, :created_at, :updated_at,
                 :published_on, :nr_of_linked_children
      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
