# frozen_string_literal: true

class ReportDatatable < CustomDatatable
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers

  TABLE_COLUMNS = %w(
    Report.project_name
    Report.name
    Report.pdf_file
    Report.docx_file
    Report.created_by
    Report.modified_by
    Report.created_at
    Report.updated_at
  ).freeze

  def_delegator :@view, :edit_project_report_path
  def initialize(view, user, reports)
    super(view)
    @user    = user
    @reports = reports
  end

  def sortable_columns
    @sortable_columns ||= TABLE_COLUMNS
  end

  def searchable_columns
    @searchable_columns ||= TABLE_COLUMNS
  end

  def sort_records(records)
    case sort_column(order_params)
    when 'reports.docx_file'
      records.left_joins(:docx_file_attachment)
             .order(active_storage_attachments: sort_direction(order_params))
             .order(docx_file_processing: sort_direction(order_params) == 'ASC' ? :desc : :asc)
    when 'reports.pdf_file'
      records.left_joins(:pdf_file_attachment)
             .order(active_storage_attachments: sort_direction(order_params))
             .order(pdf_file_processing: sort_direction(order_params) == 'ASC' ? :desc : :asc)
    else
      sort_by = "#{sort_column(order_params)} #{sort_direction(order_params)}"
      records.order(sort_by)
    end
  end

  private

  def data
    records.map do |record|
      {
        '0' => record.id,
        '1' => sanitize_input(record.project_name),
        '2' => sanitize_input(record.name),
        '3' => pdf_file(record),
        '4' => docx_file(record),
        '5' => sanitize_input(record.created_by),
        '6' => sanitize_input(record.modified_by),
        '7' => I18n.l(record.created_at, format: :full),
        '8' => I18n.l(record.updated_at, format: :full),
        'edit' => edit_project_report_path(record.project_id, record.id),
        'status' => status_project_report_path(record.project_id, record.id),
        'generate_pdf' => generate_pdf_project_report_path(record.project_id, record.id),
        'generate_docx' => generate_docx_project_report_path(record.project_id, record.id),
        'save_to_inventory' => save_pdf_to_inventory_modal_report_path(record.id)
      }
    end
  end

  def docx_file(report)
    docx = document_preview_report_path(report, report_type: :docx) if report.docx_file.attached?
    {
      processing: report.docx_file_processing,
      preview_url: docx,
      error: false
    }
  end

  def pdf_file(report)
    pdf = document_preview_report_path(report, report_type: :pdf) if report.pdf_file.attached?
    {
      processing: report.pdf_file_processing,
      preview_url: pdf,
      error: false
    }
  end

  def get_raw_records
    res = @reports.joins(:project)
                  .joins(
                    'LEFT OUTER JOIN users AS creators ' \
                    'ON reports.user_id = creators.id'
                  ).joins(
                    'LEFT OUTER JOIN users AS modifiers '\
                    'ON reports.last_modified_by_id = modifiers.id'
                  )
                  .select('reports.* AS reports')
                  .select('projects.name AS project_name')
                  .select('creators.full_name AS created_by')
                  .select('modifiers.full_name AS modified_by')
    Report.from(res, :reports)
  end

  def filter_records(records)
    records.where_attributes_like(
      ['project_name', 'reports.name', 'reports.description'],
      dt_params.dig(:search, :value)
    )
  end

  # ==== Insert 'presenter'-like methods below if necessary
end
