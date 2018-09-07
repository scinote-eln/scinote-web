# frozen_string_literal: true

module Api
  module V1
    class ExperimentSerializer < ActiveModel::Serializer
      type :experiments
      attributes :id, :name, :description, :project_id, :created_by_id,
                 :archived, :created_at, :updated_at
    end
  end
end
