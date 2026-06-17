# frozen_string_literal: true

module QaTools
  class ActivityStatisticsController < ApplicationController
    SORTABLE_COLUMNS = %w(type_of group group_name type type_name total_count).freeze

    def index
      @start_date = params[:start_date]&.to_date || Time.zone.today
      @end_date   = params[:end_date]&.to_date   || Time.zone.today
      @sort_column = SORTABLE_COLUMNS.include?(params[:column]) ? params[:column] : 'total_count'
      @sort_direction = params[:direction] == 'asc' ? 'asc' : 'desc'

      activity_counts =
        Activity.where(created_at: (@start_date.beginning_of_day..@end_date.end_of_day))
                .group(:type_of, :team_id)
                .pluck(:type_of, :team_id, 'count(type_of)')
                .group_by(&:first).to_h do |type_of, team_counts|
                  [
                    type_of.to_sym,
                    team_counts.to_h { |c| [Team.find(c[1]).name, c[2]] }
                  ]
                end

      activity_statistics = Extends::ACTIVITY_TYPES.map do |activity_type, type_of|
        group = Extends::ACTIVITY_GROUPS.find { |_, type_ofs| type_ofs.include?(type_of) }.first
        {
          type_of: type_of,
          type: activity_type,
          type_name: I18n.t("global_activities.activity_name.#{activity_type}"),
          group: group,
          group_name: I18n.t("global_activities.activity_group.#{group}"),
          total_count: activity_counts[activity_type]&.values&.sum || 0,
          team_counts: activity_counts[activity_type]
        }
      end

      @activity_statistics = activity_statistics.sort_by(&sort_value(@sort_column))
      @activity_statistics.reverse! if @sort_direction == 'desc'

      respond_to do |format|
        format.html
        format.csv { send_data to_csv(@activity_statistics), filename: "activity_statistics_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.csv", type: 'text/csv' }
      end
    end

    private

    def sort_value(column)
      lambda do |info|
        case column
        when 'total_count', 'type_of' then info[column.to_sym].to_i
        else info[column.to_sym].to_s.downcase
        end
      end
    end

    def to_csv(data)
      require 'csv'
      attributes = ['Type Id', 'Group', 'Group Name', 'Type', ' Type Name', 'Count', 'Workspaces']

      CSV.generate(headers: true) do |csv|
        csv << attributes
        data.each do |row|
          csv << row.values
        end
      end
    end

    helper_method :sort_header
    def sort_header(label, column)
      active = @sort_column == column
      direction = active && @sort_direction == 'asc' ? 'desc' : 'asc'
      indicator =
        if active
          @sort_direction == 'asc' ? ' ▲' : ' ▼'
        else
          ''
        end
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
