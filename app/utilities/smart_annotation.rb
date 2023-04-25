# frozen_string_literal: true

class SmartAnnotation
  include ActionView::Helpers::InputSanitizeHelper
  include ActionView::Helpers::TextHelper

  attr_writer :current_user, :current_team, :query

  def initialize(current_user, current_team, query)
    @current_user = current_user
    @current_team = current_team
    @query = query
  end

  def my_modules
    # Search tasks
    MyModule.search_by_name(@current_user, @current_team, @query, intersect: true).active
            .joins(experiment: :project)
            .where(projects: { archived: false }, experiments: { archived: false })
            .limit(Constants::ATWHO_SEARCH_LIMIT + 1)
  end

  def projects
    # Search projects
    Project.search_by_name(@current_user, @current_team, @query, intersect: true)
           .where(archived: false)
           .limit(Constants::ATWHO_SEARCH_LIMIT + 1)
  end

  def experiments
    # Search experiments
    Experiment.search_by_name(@current_user, @current_team, @query, intersect: true)
              .joins(:project)
              .where(projects: { archived: false }, experiments: { archived: false })
              .limit(Constants::ATWHO_SEARCH_LIMIT + 1)
  end

  def repository_rows(repository)
    res = RepositoryRow
          .active
          .where(repository: repository)
          .search_by_name(@current_user, @current_team, @query, intersect: true)
          .limit(Constants::ATWHO_SEARCH_LIMIT + 1)
    rep_items_list = []

    res.each do |rep_row|
      rep_item = {}
      rep_item[:id] = rep_row.id.base62_encode
      rep_item[:name] = escape_input(rep_row.name)
      rep_item[:code] = escape_input(rep_row.code)
      rep_items_list << rep_item
    end
    rep_items_list
  end
end
