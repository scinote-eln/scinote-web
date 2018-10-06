# frozen_string_literal: true

module Api
  module V1
    class ProtocolSerializer < ActiveModel::Serializer
      type :protocols
      attributes :id, :name, :authors, :description,
                 :team_id, :protocol_type,
                 :nr_of_linked_children
      attribute :my_module_id, key: :task_id

      belongs_to :my_module, serializer: TaskSerializer
    end
  end
end
