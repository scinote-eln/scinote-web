class AtWhoController < ApplicationController
  before_action :load_vars
  before_action :check_users_permissions

  def users
    scope = @team.search_users(@query).limit(Constants::ATWHO_SEARCH_LIMIT + 1)
    @users = scope.limit(Constants::ATWHO_SEARCH_LIMIT)
    @limit_reached = limit_reached?(scope)
  end

  # Unified '#' reference search: no `parent_type` -> cross-type search; `parent_type` alone ->
  # root listing of that type; `parent_type` + `parent_id` -> that specific object's children
  # (a drill-down step). See SmartAnnotation#search/#global_search for the dispatch.
  def search
    annotation = SmartAnnotation.new(current_user, current_team, @query)
    result = if params[:parent_type].present?
               annotation.search(parent_type: params[:parent_type], parent_id: params[:parent_id],
                                  assignable_my_module_id: assignable_my_module_id)
             else
               annotation.global_search(assignable_my_module_id: assignable_my_module_id)
             end

    @items = result[:items]
    @limit_reached = result[:limit_reached]
  end

  private

  def load_vars
    @team = Team.find_by_id(params[:id])
    @query = params[:query]
    @team_id = current_team&.id
    render_404 unless @team
  end

  def check_users_permissions
    render_403 unless can_read_team?(@team)
  end

  def limit_reached?(collection)
    collection.length == Constants::ATWHO_SEARCH_LIMIT + 1
  end

  def assignable_my_module_id
    return unless params[:assignable_my_module_id].present?

    MyModule.readable_by_user(current_user, @team).find_by(id: params[:assignable_my_module_id])&.id
  end
end
