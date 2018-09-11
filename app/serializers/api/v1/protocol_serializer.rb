# frozen_string_literal: true

module Api
  module V1
    class ProtocolSerializer < ActiveModel::Serializer
      type :protocols
      attributes :id, :name, :authors, :description,
                 :my_module_id, :team_id, :protocol_type,
                 :nr_of_linked_children
      belongs_to :my_module, serializer: MyModuleSerializer
    end
  end
end
