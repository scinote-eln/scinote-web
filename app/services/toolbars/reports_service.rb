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
        icon: 'sn-icon sn-icon-edit',
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
        type: :emit
      }
    end

    def save_pdf_to_inventory_action
      return unless @report && can_manage_report?(@report)

      {
        name: 'save_pdf_to_repository',
        label: I18n.t('projects.reports.index.save_pdf_to_inventory'),
        icon: 'fas fa-save',
        type: :emit
      }
    end

    def generate_docx_action
      return unless @report && can_manage_report?(@report)

      button_id = @report.docx_file_status == 'docx_empty' ? 'requestDocx' : 'updateDocx'
      label = @report.docx_file_status == 'docx_empty' ? I18n.t('projects.reports.index.request_docx') : I18n.t('projects.reports.index.update_docx')

      {
        name: 'update_docx',
        label: label,
        icon: 'sn-icon sn-icon-file-word',
        type: :emit
      }
    end

    def delete_action
      return unless @reports.all? { |report| can_manage_report?(report) }

      {
        name: 'delete',
        label: I18n.t('projects.reports.index.delete'),
        icon: 'sn-icon sn-icon-delete',
        path: reports_destroy_path,
        type: :emit
      }
    end
  end
end
