# frozen_string_literal: true

module ActiveStorage
  class BlobSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :filename, :extension, :basename, :url, :created_at, :byte_size, :version, :restored_from_version, :created_by, :download_url

    def basename
      object.filename.base
    end

    def extension
      object.filename.extension_without_delimiter
    end

    def download_url
      rails_blob_url(object, disposition: 'attachment')
    end

    def version
      object.metadata['version'] || 1
    end

    def restored_from_version
      object.metadata['restored_from_version']
    end

    def created_at
      return object.created_at unless @instance_options[:user]

      object.created_at.strftime("#{@instance_options[:user].date_format}, %H:%M")
    end

    def created_by
      User.select(:id, :full_name, :email).find_by(
        id: object.metadata['created_by_id'] || object.attachments.first&.record&.created_by_id
      )
    end
  end
end
