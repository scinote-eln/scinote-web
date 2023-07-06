# frozen_string_literal: true

module Dashboard
  class CalendarsController < ApplicationController
    include IconsHelper
    include MyModulesHelper

    def show
      date = params[:date].in_time_zone(current_user.time_zone)
      start_date = date.at_beginning_of_month.utc - 8.days
      end_date = date.at_end_of_month.utc + 15.days
      due_dates = current_user.my_modules.active.uncomplete
                              .joins(experiment: :project)
                              .where(experiments: { archived: false })
                              .where(projects: { archived: false })
                              .where('my_modules.due_date > ? AND my_modules.due_date < ?', start_date, end_date)
                              .joins(:protocols).where(protocols: { team_id: current_team.id })
                              .pluck(:due_date)
      render json: { events: due_dates.map { |i| { date: i.to_date } } }
    end

    def day
      date = params[:date].in_time_zone(current_user.time_zone)
      start_date = date.utc
      end_date = date.end_of_day.utc
      my_modules = current_user.my_modules.active.uncomplete
                               .joins(experiment: :project)
                               .where(experiments: { archived: false })
                               .where(projects: { archived: false })
                               .where('my_modules.due_date > ? AND my_modules.due_date < ?', start_date, end_date)
                               .where(projects: { team_id: current_team.id })
      render json: {
        html: render_to_string(partial: 'shared/my_modules_list_partial',
                               locals: { my_modules: my_modules },
                               formats: :html)
      }
    end
  end
end
