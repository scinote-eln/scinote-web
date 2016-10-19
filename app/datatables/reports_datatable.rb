class ReportsDatatable < AjaxDatatablesRails::Base
  include Rails.application.routes.url_helpers
  def_delegator :@view, :link_to
  def_delegator :@view, :check_box_tag

  def initialize(view_context,
                 user,
                 organization)
    super(view_context)
    @user = user
    @organization = organization
  end

  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= [
      'Report.name',
      'Report.user.name',
      'Report.last_modified_by.name',
      'Report.created_at',
      'Report.updated_at',
      'Project.name'
    ]
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= [
      'Report.name',
      'Report.user.name',
      'Report.last_modified_by.name',
      'Report.created_at',
      'Report.updated_at',
      'Project.name'
    ]
  end

  private

  def data
    records.map do |record|
      [
        # comma separated list of the values for each cell of a table row
        # example: record.attribute,
        check_box_tag('report', record.id),
        link_to(record.name, edit_report_path(record)),
        record.user.name,
        record.last_modified_by.name,
        I18n.l(record.created_at, format: :full),
        I18n.l(record.updated_at, format: :full),
        link_to(record.project.name, project_path(record.project))
      ]
    end
  end

  def get_raw_records
    Report
      .joins(:project)
      .where('reports.user_id = ? AND projects.organization_id = ?',
             @user,
             @organization)
  end

  # ==== Insert 'presenter'-like methods below if necessary
end
