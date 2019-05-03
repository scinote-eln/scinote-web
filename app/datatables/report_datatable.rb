# frozen_string_literal: true

class ReportDatatable < CustomDatatable
  include InputSanitizeHelper

  TABLE_COLUMNS = %w(
    Report.project_name
    Report.name
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

  private

  def data
    records.map do |record|
      {
        '0' => record.id,
        '1' => sanitize_input(record.project_name),
        '2' => sanitize_input(record.name),
        '3' => sanitize_input(record.created_by),
        '4' => sanitize_input(record.modified_by),
        '5' => I18n.l(record.created_at, format: :full),
        '6' => I18n.l(record.updated_at, format: :full),
        'edit' => edit_project_report_path(record.project_id, record.id)
      }
    end
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

  # ==== Insert 'presenter'-like methods below if necessary
end
