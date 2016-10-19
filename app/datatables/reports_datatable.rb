class ReportsDatatable < AjaxDatatablesRails::Base
  include Rails.application.routes.url_helpers
  def_delegator :@view, :link_to
  def_delegator :@view, :check_box_tag
  def_delegator :@view, :h

  def initialize(view_context,
                 user,
                 organization)
    super(view_context)
    @user = user
    @organization = organization
  end

  def view_columns
    @view_columns ||= {
      id: { source: "Subject.id", cond: :eq },
      name: { source: "Subject.name" },
      suggest: { source: "Subject.suggest" },
      usage_count: { source: "usage_count" }
    }
  end

  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= [
      'Report.id',
      'Report.name',
      'Report.user_id',
      'Report.last_modified_by_id',
      'Report.created_at',
      'Report.updated_at',
      'Report.project_id'
    ]
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= [
      'Report.id',
      'Report.name',
      'Report.user_id',
      'Report.last_modified_by_id',
      'Report.created_at',
      'Report.updated_at',
      'Report.project_id'
    ]
  end

  private

  def data
    records.map do |record|
      [
        # comma separated list of the values for each cell of a table row
        # example: record.attribute,
        check_box_tag('report',
                      record.id,
                      false,
                      class: 'check-report',
                      data: { editLink: edit_report_path(record) }),
        record.name,
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
      .joins(:user)
      .where('reports.user_id = ? AND projects.organization_id = ?',
             @user,
             @organization)
  end

  # ==== Insert 'presenter'-like methods below if necessary
end
