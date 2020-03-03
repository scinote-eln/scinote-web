# frozen_string_literal: true

module Dashboard
  class CalendarsController < ApplicationController
    include IconsHelper

    def show
      date = DateTime.parse(params[:date])
      start_date = date.at_beginning_of_month.utc - 7.days
      end_date = date.at_end_of_month.utc + 14.days
      due_dates = current_user.my_modules.active.uncomplete
                              .joins(experiment: :project)
                              .where(experiments: { archived: false })
                              .where(projects: { archived: false })
                              .where('my_modules.due_date > ? AND my_modules.due_date < ?', start_date, end_date)
                              .joins(:protocols).where(protocols: { team_id: current_team.id })
                              .pluck(:due_date)
      render json: { events: due_dates.map { |i| { date: i } } }
    end

    def day
      date = DateTime.parse(params[:date]).utc
      my_modules = current_user.my_modules.active.uncomplete
                               .joins(experiment: :project)
                               .where(experiments: { archived: false })
                               .where(projects: { archived: false })
                               .where('DATE(my_modules.due_date) = DATE(?)', date)
                               .where(projects: { team_id: current_team.id })
                               .my_modules_list_partial
      render json: {
        html: render_to_string(partial: 'shared/my_modules_list_partial.html.erb', locals: { task_groups: my_modules })
      }
    end
  end
end
