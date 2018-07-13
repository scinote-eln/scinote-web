# frozen_string_literal: true

class ReportDatatable < CustomDatatable
  include InputSanitizeHelper

  TABLE_COLUMNS = %w(
    Views::Datatables::DatatablesReport.project_name
    Views::Datatables::DatatablesReport.name
    Views::Datatables::DatatablesReport.created_by
    Views::Datatables::DatatablesReport.last_modified_by
    Views::Datatables::DatatablesReport.created_at
    Views::Datatables::DatatablesReport.updated_at
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

  private

  def data
    records.map do |record|
      {
        '0'    => record.id,
        '1'    => sanitize_input(record.project_name),
        '2'    => sanitize_input(record.name),
        '3'    => sanitize_input(record.created_by),
        '4'    => sanitize_input(record.last_modified_by),
        '5'    => I18n.l(record.created_at, format: :full),
        '6'    => I18n.l(record.updated_at, format: :full),
        'edit' => edit_project_report_path(record.project_id, record.id)
      }
    end
  end

  def get_raw_records
    @reports
  end

  # ==== Insert 'presenter'-like methods below if necessary
end
