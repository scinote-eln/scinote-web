# frozen_string_literal: true

module Api
  module V1
    class TaskSerializer < ActiveModel::Serializer
      type :tasks
      attributes :id, :name, :due_date, :description, :state, :archived
    end
  end
end
