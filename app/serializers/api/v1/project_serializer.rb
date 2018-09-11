# frozen_string_literal: true

module Api
  module V1
    class ProjectSerializer < ActiveModel::Serializer
      type :projects
      attributes :id, :name, :visibility, :due_date,
                 :archived, :experiments_order

      belongs_to :team, serializer: TeamSerializer
    end
  end
end
