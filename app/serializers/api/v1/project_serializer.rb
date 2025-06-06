# frozen_string_literal: true

module Api
  module V1
    class ProjectSerializer < ActiveModel::Serializer
      type :projects
      attributes :name, :status, :visibility, :start_date, :archived, :started_at, :done_at, :start_date, :due_date, :description
      attribute :metadata, if: -> { scope && scope[:metadata] == true }

      belongs_to :project_folder, serializer: ProjectFolderSerializer
      belongs_to :supervised_by, serializer: UserSerializer
      has_many :project_comments, key: :comments, serializer: CommentSerializer

      include TimestampableModel

      def start_date
        object.created_at
      end
    end
  end
end
