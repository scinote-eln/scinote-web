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
        object.pdf_file.url if object.pdf_file.attached?
      end

      def docx_file_size
        object.docx_file.blob.byte_size
      end

      def docx_file_url
        object.docx_file.url if object.docx_file.attached?
      end
    end
  end
end
