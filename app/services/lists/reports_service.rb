# frozen_string_literal: true

module Lists
  class ReportsService < BaseService
    private

    def fetch_records
      res = @raw_data.joins(:project)
                     .joins(
                       'LEFT OUTER JOIN users AS creators ' \
                       'ON reports.user_id = creators.id'
                     ).joins(
                       'LEFT OUTER JOIN users AS modifiers ' \
                       'ON reports.last_modified_by_id = modifiers.id'
                     )
                     .select('reports.* AS reports')
                     .select('projects.name AS project_name')
                     .select('creators.full_name AS created_by_name')
                     .select('modifiers.full_name AS modified_by_name')
      @records = Report.from(res, :reports)
    end

    def filter_records
      return unless @params[:search]

      @records = @records.where_attributes_like(
        ['project_name', 'reports.name', 'reports.description', "('RP' || reports.id)"],
        @params[:search]
      )
    end

    def sortable_columns
      @sortable_columns ||= {
        project_name: 'Report.project_name',
        report_name: 'Report.name',
        id: 'Report.code',
        pdf: 'Report.pdf_file',
        docx: 'Report.docx_file',
        created_by: 'Report.created_by_name',
        last_modified_by: 'Report.modified_by_name',
        created_date: 'Report.created_at',
        last_update_date: 'Report.updated_at'
      }
    end
  end
end
