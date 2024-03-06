# frozen_string_literal: true

module Lists
  class ReportSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    attributes :name, :code, :project_name, :pdf_file, :docx_file, :created_by_name,
               :modified_by_name, :created_at, :updated_at, :urls

    def project_name
      object['project_name']
    end

    def created_by_name
      object['created_by_name']
    end

    def modified_by_name
      object['modified_by_name']
    end

    def created_at
      I18n.l(object.created_at, format: :full)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full)
    end

    def archived
      object.project.archived?
    end

    def docx_file
      docx = document_preview_report_path(object, report_type: :docx) if object.docx_file.attached?
      {
        processing: object.docx_processing?,
        preview_url: docx,
        error: object.docx_error?
      }
    end

    def pdf_file
      pdf = document_preview_report_path(object, report_type: :pdf) if object.pdf_file.attached?
      {
        processing: object.pdf_processing?,
        preview_url: pdf,
        error: object.pdf_error?
      }
    end

    def urls
      {
        edit: edit_project_report_path(object.project_id, object.id),
        status: status_project_report_path(object.project_id, object.id),
        generate_pdf: generate_pdf_project_report_path(object.project_id, object.id),
        generate_docx: generate_docx_project_report_path(object.project_id, object.id),
        save_to_inventory: save_pdf_to_inventory_item_report_path(object)
      }
    end
  end
end
