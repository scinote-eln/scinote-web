# frozen_string_literal: true

module Lists
  class ReportsService < BaseService
    private

    def fetch_records
      @records = @raw_data.joins(
        'LEFT OUTER JOIN users AS creators ' \
        'ON reports.user_id = creators.id'
      ).joins(
        'LEFT OUTER JOIN users AS modifiers ' \
        'ON reports.last_modified_by_id = modifiers.id'
      )
                          .joins(:project)
                          .select('reports.* AS reports')
                          .select('projects.name AS project_name')
                          .select('creators.full_name AS created_by_name')
                          .select('modifiers.full_name AS modified_by_name')
    end

    def filter_records
      return if @params[:search].blank?

      @records = @records.where_attributes_like(
        ['reports.name',
         'reports.description',
         "('RP' || reports.id)",
         'projects.name',
         'creators.full_name',
         'modifiers.full_name'],
        @params[:search]
      )
    end

    def sort_records
      return unless @params[:order]

      case order_params[:column]
      when 'docx_file'
        @records = @records.left_joins(:docx_file_attachment)
                           .order(active_storage_attachments: sort_direction(order_params))
                           .order(docx_file_status: sort_direction(order_params) == 'ASC' ? :desc : :asc)
      when 'pdf_file'
        @records = @records.left_joins(:pdf_file_attachment)
                           .order(active_storage_attachments: sort_direction(order_params))
                           .order(pdf_file_status: sort_direction(order_params) == 'ASC' ? :desc : :asc)
      when 'code'
        sort_by = "reports.id #{sort_direction(order_params)}"
        @records = @records.order(sort_by)
      else
        sort_by = "#{sortable_columns[order_params[:column].to_sym]} #{sort_direction(order_params)}"
        @records = @records.order(sort_by)
      end
      @records = @records.order(:id)
    end

    def sortable_columns
      @sortable_columns ||= {
        name: 'reports.name',
        modified_by_name: 'modifiers.full_name',
        created_by_name: 'creators.full_name',
        project_name: 'projects.name',
        created_at: 'reports.created_at',
        updated_at: 'reports.updated_at'
      }
    end
  end
end
