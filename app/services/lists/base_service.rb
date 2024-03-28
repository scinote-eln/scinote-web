# frozen_string_literal: true

module Lists
  class BaseService
    def initialize(raw_data, current_user, params)
      @raw_data = raw_data
      @current_team = current_user.current_team
      @params = params
      @filters = params[:filters] || {}
      @records = []
      @shared_sort_query = prepare_case_statement
    end

    def call
      fetch_records(@shared_sort_query)
      filter_records
      sort_records
      paginate_records
      @records
    end

    private

    def fetch_records
      raise NotImplementedError
    end

    def order_params
      @order_params ||= @params.require(:order).permit(:column, :dir).to_h
    end

    def paginate_records
      @records = @records.page(@params[:page]).per(@params[:per_page])
    end

    def sort_direction(order_params)
      order_params[:dir] == 'asc' ? 'ASC' : 'DESC'
    end

    def sort_records
      return unless @params[:order] &&
                    (sortable_columns[order_params[:column].to_sym].present? || should_sort_by_shared_label?)

      sort_by = if should_sort_by_shared_label?
                  "#{@shared_sort_query} #{sort_direction(order_params)}"
                else
                  "#{sortable_columns[order_params[:column].to_sym]} #{sort_direction(order_params)}"
                end
      @records = @records.order(Arel.sql(sort_by)).order(:id)
    end

    def should_sort_by_shared_label?
      @params[:order].present? && @params[:order][:column].to_s == 'shared_label'
    end

    def prepare_case_statement
      return unless should_sort_by_shared_label?

      shared_write_value = Repository.permission_levels['shared_write']
      not_shared_value = Repository.permission_levels['not_shared']
      team_id = @current_team.id

      case_statement = <<-SQL.squish
        CASE
          WHEN repositories.team_id = :team_id AND repositories.permission_level NOT IN (:not_shared_value)
            OR EXISTS (
            SELECT 1 FROM team_shared_objects
            WHERE team_shared_objects.shared_object_id = repositories.id
              AND team_shared_objects.shared_object_type = 'RepositoryBase'
            ) THEN 1
          WHEN repositories.team_id != :team_id AND repositories.permission_level NOT IN (:not_shared_value)
            OR EXISTS (
            SELECT 1 FROM team_shared_objects
            WHERE team_shared_objects.shared_object_id = repositories.id
              AND team_shared_objects.shared_object_type = 'RepositoryBase'
              AND team_shared_objects.team_id = :team_id
          ) THEN
              CASE
                WHEN repositories.permission_level IN (:shared_write_value)
                  OR EXISTS (
                    SELECT 1 FROM team_shared_objects
                    WHERE team_shared_objects.shared_object_id = repositories.id
                      AND team_shared_objects.shared_object_type = 'RepositoryBase'
                      AND team_shared_objects.permission_level = :shared_write_value
                      AND team_shared_objects.team_id = :team_id
                  ) THEN 2
                ELSE 3
              END
          ELSE 4
        END
      SQL

      ActiveRecord::Base.sanitize_sql_array(
        [case_statement, { team_id:, not_shared_value:, shared_write_value: }]
      )
    end
  end
end
