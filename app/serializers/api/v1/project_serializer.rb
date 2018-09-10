# frozen_string_literal: true

module Api
  module V1
    class ProjectSerializer < ActiveModel::Serializer
      type :projects
      attributes :id, :name, :visibility, :due_date, :team_id, :created_at,
                 :updated_at, :archived, :archived_on, :created_by_id,
                 :last_modified_by_id, :archived_by_id, :restored_by_id,
                 :restored_on, :experiments_order

      belongs_to :team, serializer: TeamSerializer
    end
  end
end
