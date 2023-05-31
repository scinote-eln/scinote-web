# frozen_string_literal: true

module Toolbars
  class ReportsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, report_ids: [])
      @current_user = current_user
      @reports = Report.where(id: report_ids)
      @report = @reports.first if @reports.length == 1
    end

    def actions
      return [] if @reports.none?

      [
        edit_action,
        update_pdf_action,
        save_pdf_to_inventory_action,
        generate_docx_action,
        delete_action
      ].compact
    end

    private

    def edit_action
      return unless @report && can_manage_report?(@report)

      {
        name: 'edit',
        label: I18n.t('projects.reports.index.edit'),
        icon: 'fas fa-pencil-alt',
        button_id: 'edit-report-btn',
        path: edit_project_report_path(@report.project_id, @report.id),
        type: :link
      }
    end

    def update_pdf_action
      return unless @report && can_manage_report?(@report)

      {
        name: 'update_pdf',
        label: I18n.t('projects.reports.index.update_pdf'),
        icon: 'fas fa-file-pdf',
        button_id: 'updatePdf'
      }
    end

    def save_pdf_to_inventory_action
      return unless @report && can_manage_report?(@report)

      {
        name: 'save_pdf_to_inventory',
        label: I18n.t('projects.reports.index.save_pdf_to_inventory'),
        icon: 'fas fa-save',
        button_id: 'savePdfToInventoryButton',
        path: save_pdf_to_inventory_modal_report_path(@report.id)
      }
    end

    def generate_docx_action
      return unless @report && can_manage_report?(@report)

      button_id = @report.docx_file_status == 'docx_empty' ? 'requestDocx' : 'updateDocx'
      label = @report.docx_file_status == 'docx_empty' ? I18n.t('projects.reports.index.request_docx') : I18n.t('projects.reports.index.update_docx')

      {
        name: 'generate_docx_action',
        label: label,
        icon: 'fas fa-file-word',
        button_id: button_id
      }
    end

    def delete_action
      return unless @reports.all? { |report| can_manage_report?(report) }

      {
        name: 'delete',
        label: I18n.t('projects.reports.index.delete'),
        icon: 'fas fa-trash',
        button_id: 'delete-reports-btn',
        type: :link
      }
    end
  end
end
