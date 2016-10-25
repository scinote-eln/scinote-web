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

  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= [
      'Report.id',
      'Report.name',
      'User.full_name',
      'User.full_name',
      'Report.created_at',
      'Report.updated_at',
      'Project.name'
    ]
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= [
      'Report.id',
      'Report.name',
      'User.full_name',
      'User.full_name',
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
        check_box_tag('report',
                      record.id,
                      false,
                      class: 'check-report',
                      data: { editLink: edit_report_path(record),
                              editable: record.project.active? }),
        report_name(record),
        record.user.name,
        record.last_modified_by.name,
        I18n.l(record.created_at, format: :full),
        I18n.l(record.updated_at, format: :full),
        project_link(record)
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

  def report_name(record)
    "#{record.name} <span class='label label-warning'> \
    #{I18n.t('projects.reports.index.archived') if record.project.archived?} \
    </span>"
  end

  def project_link(record)
    return link_to(record.project.name,
                   project_path(record.project)) if record.project.active?

    link_to(record.project.name, projects_archive_path)
  end
end
