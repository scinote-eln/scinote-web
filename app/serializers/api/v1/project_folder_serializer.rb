# frozen_string_literal: true

module Api
  module V1
    class ProjectFolderSerializer < ActiveModel::Serializer
      type :project_folders
      attributes :id, :name

      belongs_to :team, serializer: TeamSerializer
      belongs_to :parent_folder, serializer: ProjectFolderSerializer
      has_many :projects, serializer: ProjectSerializer
      has_many :project_folders, serializer: ProjectFolderSerializer
<<<<<<< HEAD

      include TimestampableModel
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    end
  end
end
