# frozen_string_literal: true

module Api
  module V1
    class ProjectSerializer < ActiveModel::Serializer
      type :projects
      attributes :name, :visibility, :start_date, :archived

      belongs_to :project_folder, serializer: ProjectFolderSerializer
      has_many :project_comments, key: :comments, serializer: CommentSerializer

      include TimestampableModel

      def start_date
        object.created_at
      end
    end
  end
end
