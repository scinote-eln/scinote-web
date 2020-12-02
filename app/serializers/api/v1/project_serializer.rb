# frozen_string_literal: true

module Api
  module V1
    class ProjectSerializer < ActiveModel::Serializer
      type :projects
      attributes :name, :visibility, :start_date, :archived

      belongs_to :project_folder, serializer: ProjectFolderSerializer

      def start_date
        I18n.l(object.created_at, format: :full)
      end
    end
  end
end
