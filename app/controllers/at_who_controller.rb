class AtWhoController < ApplicationController
  include InputSanitizeHelper

  before_action :load_vars
  before_action :check_users_permissions

  def users
    users = @team.search_users(@query).limit(Constants::ATWHO_SEARCH_LIMIT + 1)
    respond_to do |format|
      format.json do
        render json: {
          users: [render_to_string(partial: 'shared/smart_annotation/users.html.erb', locals: {users: users})],
          status: :ok
        }
      end
    end
  end

  def menu_items
    res = SmartAnnotation.new(current_user, current_team, @query)

    respond_to do |format|
      format.json do
        render json: {
          prj: res.projects,
          exp: res.experiments,
          tsk: res.my_modules,
          status: :ok
        }
      end
    end
  end

  def rep_items
    repository =
      if params[:repository_id].present?
        Repository.find_by(id: params[:repository_id])
      else
        Repository.active.accessible_by_teams(@team).first
      end
    if repository && can_read_repository?(repository)
      items = SmartAnnotation.new(current_user, current_team, @query)
                             .repository_rows(repository, params[:assignable_my_module_id])
      repository_id = repository.id
    else
      items = []
      repository_id = nil
    end
    respond_to do |format|
      format.json do
        render json: {
          res: [
            render_to_string(partial: 'shared/smart_annotation/repository_items.html.erb',
                             locals: { repository_rows: items, repository: repository })
          ],
          repository: repository_id,
          team: current_team.id
        }
      end
    end
  end

  def menu
    repositories = Repository.active.accessible_by_teams(@team)
    render json: { html: render_to_string({ partial: "shared/smart_annotation/menu.html.erb",
                                            locals: { repositories: repositories } }) }
  end

  def projects
    res = SmartAnnotation.new(current_user, current_team, @query)
    respond_to do |format|
      format.json do
        render json: {
          res: [render_to_string(partial: 'shared/smart_annotation/project_items.html.erb', locals: {
                                 projects: res.projects
                               })],
          team: current_team.id,
          status: :ok
        }
      end
    end
  end

  def experiments
    res = SmartAnnotation.new(current_user, current_team, @query)
    respond_to do |format|
      format.json do
        render json: {
          res: [render_to_string(partial: 'shared/smart_annotation/experiment_items.html.erb', locals: {
                                 experiments: res.experiments
                               })],
          team: current_team.id,
          status: :ok
        }
      end
    end
  end

  def my_modules
    res = SmartAnnotation.new(current_user, current_team, @query)
    respond_to do |format|
      format.json do
        render json: {
          res: [render_to_string(partial: 'shared/smart_annotation/my_module_items.html.erb', locals: {
                                 my_modules: res.my_modules
                               })],
          team: current_team.id,
          status: :ok
        }
      end
    end
  end

  private

  def load_vars
    @team = Team.find_by_id(params[:id])
    @query = params[:query]
    render_404 unless @team
  end

  def check_users_permissions
    render_403 unless can_read_team?(@team)
  end
end
