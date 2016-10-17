class ReportsDatatable < AjaxDatatablesRails::Base
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
      'Report.created_at',
      'Report.updated_at',
      'Report.project'
    ]
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= [
      'Report.name',
      'Report.created_at',
      'Report.updated_at',
      'Report.project'
    ]
  end

  private

  def data
    records.map do |record|
      [
        # comma separated list of the values for each cell of a table row
        # example: record.attribute,
        '0' => record.name,
        '1' => record.created_at,
        '2' => record.updated_at,
        '3' => record.project.name
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
