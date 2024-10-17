# frozen_string_literal: true

module ActiveStorage
  class BlobSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :filename, :url, :created_at, :byte_size, :version, :restored_from_version, :created_by

    def version
      object.metadata['version'] || 1
    end

    def restored_from_version
      object.metadata['restored_from_version']
    end

    def created_at
      object.created_at.strftime('%B %d, %Y at %H:%M')
    end

    def created_by
      User.select(:id, :full_name, :email).find_by(
        id: object.metadata['created_by_id'] || object.attachments.first&.record&.created_by_id
      )
    end
  end
end
