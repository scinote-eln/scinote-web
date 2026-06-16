module QaTools
  class ActivityStatisticsController < ApplicationController
    SORTABLE_COLUMNS = %w(type_id group type name count).freeze
    helper_method :sort_header

    def index
      @start_date = import_params[:start_date]&.to_date || Date.today
      @end_date   = import_params[:end_date]&.to_date   || Date.today
      @sort_column = SORTABLE_COLUMNS.include?(params[:column]) ? params[:column] : 'count'
      @sort_direction = params[:direction] == 'asc' ? 'asc' : 'desc'
      
      activities = Activity.where(created_at: (@start_date.beginning_of_day..@end_date.end_of_day))
      activity_count = normalize_type_keys(activities.group(:type_of).count)

      # Workspaces: { type_id => { team_name => count } }
      workspaces = Hash.new { |h, k| h[k] = {} }
      activities.joins(:team).group(:type_of, 'teams.name').count.each do |(type, team_name), n|
        workspaces[Activity.type_ofs[type.to_s]][team_name] = n
      end

      # Reverse map: activity type id => group key
      activity_group_ids = Extends::ACTIVITY_GROUPS.each_with_object({}) do |(group, ids), m|
        ids.each { |id| m[id] = group }
      end

      stats = Activity.type_ofs.map do |type_key, type_id|
        group_key = activity_group_ids[type_id]
        {
          type_id: type_id,
          group: I18n.t("global_activities.activity_group.#{group_key}"),
          type: type_key,
          name: I18n.t("global_activities.activity_name.#{type_key}"),
          count: activity_count.fetch(type_id, 0),
          workspaces: workspaces[type_id]
        }
      end
      
      @stats = stats.sort_by(&sort_value(@sort_column))
      @stats.reverse! if @sort_direction == 'desc'
      
      respond_to do |format|
        format.html
        format.csv { send_data to_csv(@stats), filename: "activity_statistics_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv", type: 'text/csv'}
      end
    end

    
    private
    
    def import_params
      params.permit(:start_date, :end_date, :direction, :column).to_h
    end

    def sort_value(column)
      lambda do |info|
        case column
        when 'count', 'type_id' then info[column.to_sym].to_i
        else info[column.to_sym].to_s.downcase
        end
      end
    end

    def normalize_type_key(value)
      Activity.type_ofs[value.to_s]
    end

    def normalize_type_keys(hash)
      hash.transform_keys { |k| normalize_type_key(k) }
    end
    
    def to_csv(data)
    require 'csv'
    attributes = %w{'Type ID' Group Type Name Count Workspaces}

    CSV.generate(headers: true) do |csv|
      csv << attributes
      data.each do |row|
        csv << row.values
      end
    end
  end

    def sort_header(label, column)
      active = @sort_column == column
      direction = active && @sort_direction == 'asc' ? 'desc' : 'asc'
      indicator = active ? (@sort_direction == 'asc' ? ' ▲' : ' ▼') : ''
      url = qa_tools_activity_statistics_path(
        column: column,
        direction: direction,
        start_date: params[:start_date],
        end_date: params[:end_date]
      )
      view_context.link_to("#{label}#{indicator}", url)
    end
  end
end
