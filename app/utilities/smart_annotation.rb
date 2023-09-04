# frozen_string_literal: true

class SmartAnnotation
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper

  attr_writer :current_user, :current_team, :query

  def initialize(current_user, current_team, query)
    @current_user = current_user
    @current_team = current_team
    @query = query
  end

  def my_modules
    # Search tasks
    MyModule.search_by_name_and_id(@current_user, @current_team, @query).active
            .joins(experiment: :project)
            .where(projects: { archived: false }, experiments: { archived: false })
            .limit(Constants::ATWHO_SEARCH_LIMIT + 1)
  end

  def projects
    # Search projects
    Project.search_by_name_and_id(@current_user, @current_team, @query)
           .where(archived: false)
           .limit(Constants::ATWHO_SEARCH_LIMIT + 1)
  end

  def experiments
    # Search experiments
    Experiment.search_by_name_and_id(@current_user, @current_team, @query)
              .joins(:project)
              .where(projects: { archived: false }, experiments: { archived: false })
              .limit(Constants::ATWHO_SEARCH_LIMIT + 1)
  end

  def repository_rows(repository, my_module_id)
    res = repository
          .repository_rows
          .active
          .search_by_name_and_id(@current_user, @current_team, @query)
          .limit(Constants::ATWHO_SEARCH_LIMIT + 1)

    if my_module_id.present?
      res = res.joins('LEFT OUTER JOIN "my_module_repository_rows" "current_my_module_repository_rows" ' \
                      'ON "current_my_module_repository_rows"."repository_row_id" = "repository_rows"."id" ' \
                      'AND "current_my_module_repository_rows"."my_module_id" = ' + Integer(my_module_id).to_s)
               .select('repository_rows.*',
                       'CASE WHEN current_my_module_repository_rows.id IS NOT NULL ' \
                       'THEN true ELSE false END as row_assigned')
    end
    rep_items_list = []

    res.each do |rep_row|
      rep_item = {}
      rep_item[:id] = rep_row.id
      rep_item[:id_encoded] = rep_row.id.base62_encode
      rep_item[:name] = escape_input(rep_row.name)
      rep_item[:code] = escape_input(rep_row.code)
      if my_module_id.present?
        rep_item[:row_assigned] = rep_row&.row_assigned
        rep_item[:my_module_id] = my_module_id
      end
      rep_items_list << rep_item
    end
    rep_items_list
  end
end
