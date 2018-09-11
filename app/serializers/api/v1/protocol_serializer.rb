# frozen_string_literal: true

module Api
  module V1
    class ProtocolSerializer < ActiveModel::Serializer
      type :protocols
      attributes :id, :name, :authors, :description, :added_by_id,
                 :my_module_id, :team_id, :protocol_type, :parent_id,
                 :nr_of_linked_children
      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
