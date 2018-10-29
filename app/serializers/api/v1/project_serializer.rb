# frozen_string_literal: true

module Api
  module V1
    class ProjectSerializer < ActiveModel::Serializer
      type :projects
      attributes :name, :visibility, :start_date, :archived

      def start_date
        object.created_at
      end
    end
  end
end
