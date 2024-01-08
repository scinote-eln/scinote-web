# frozen_string_literal: true

module Lists
  class ReportSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    include Canaid::Helpers::PermissionsHelper

    type :reports
    attributes :id, :name, :description
    attribute :pdf_file_size, if: -> { object.pdf_file.attached? }
    attribute :pdf_file_url, if: -> { object.pdf_file.attached? }
    attribute :docx_file_size, if: -> { object.docx_file.attached? }
    attribute :docx_file_url, if: -> { object.docx_file.attached? }
    belongs_to :user, serializer: UserSerializer
    belongs_to :project, serializer: ProjectSerializer,
                          unless: -> { instance_options[:hide_project] }

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

    def urls
      return {} if object.none?

      {
        edit: edit_project_report_path(object.project_id, object.id),
        save_pdf_to_inventory: save_pdf_to_inventory_modal_report_path(object.id),
        generate_pdf: generate_pdf_project_report(object.project_id, object.id),
        generate_docx: generate_docx_project_report(object.project_id, object.id)
      }
    end
  end
end
