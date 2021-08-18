# frozen_string_literal: true

module Api
  module V1
    class ReportSerializer < ActiveModel::Serializer
      include Rails.application.routes.url_helpers

      type :reports
      attributes :id, :name, :description
      attribute :pdf_file_size, if: -> { object.pdf_file.attached? }
      attribute :pdf_file_url, if: -> { object.pdf_file.attached? }
      attribute :docx_file_size, if: -> { object.docx_file.attached? }
      attribute :docx_file_url, if: -> { object.docx_file.attached? }
      belongs_to :user, serializer: UserSerializer
      belongs_to :project, serializer: ProjectSerializer,
                           unless: -> { instance_options[:hide_project] }

      include TimestampableModel

      def pdf_file_size
        object.pdf_file.blob.byte_size
      end

      def pdf_file_url
        rails_blob_path(object.pdf_file, disposition: 'attachment')
      end

      def docx_file_size
        object.docx_file.blob.byte_size
      end

      def docx_file_url
        rails_blob_path(object.docx_file, disposition: 'attachment')
      end
    end
  end
end
