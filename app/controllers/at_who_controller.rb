class AtWhoController < ApplicationController
  include InputSanitizeHelper

  before_action :load_vars
  before_action :check_users_permissions

  def users
    users = @team.search_users(@query).limit(Constants::ATWHO_SEARCH_LIMIT + 1)
    render json: {
      users: [render_to_string(partial: 'shared/smart_annotation/users', locals: { users: users }, formats: :html)]
    }
  end

  def menu_items
    res = SmartAnnotation.new(current_user, current_team, @query)

    render json: {
      prj: res.projects,
      exp: res.experiments,
      tsk: res.my_modules,
      status: :ok
    }
  end

  def rep_items
    repository =
      if params[:repository_id].present?
        Repository.find_by(id: params[:repository_id])
      else
        Repository.active.accessible_by_teams(@team).first
      end

    items = []
    repository_id = nil

    if repository && can_read_repository?(repository)
      assignable_my_module =
        if params[:assignable_my_module_id].present?
          MyModule.viewable_by_user(current_user, @team).find_by(id: params[:assignable_my_module_id])
        end
      items = SmartAnnotation.new(current_user, current_team, @query)
                             .repository_rows(repository, assignable_my_module&.id)
      repository_id = repository.id
    end
    render json: {
      res: [
        render_to_string(partial: 'shared/smart_annotation/repository_items',
                         locals: { repository_rows: items, repository: repository },
                         formats: :html)
      ],
      repository: repository_id,
      team: current_team.id
    }
  end

  def menu
    repositories = Repository.active.accessible_by_teams(@team)
    render json: { 
      html: render_to_string(partial: 'shared/smart_annotation/menu',
                             locals: { repositories: repositories },
                             formats: :html)
    }
  end

  def projects
    res = SmartAnnotation.new(current_user, current_team, @query)
    render json: {
      res: [render_to_string(partial: 'shared/smart_annotation/project_items',
                             locals: { projects: res.projects },
                             formats: :html)],
      team: current_team.id
    }
  end

  def experiments
    res = SmartAnnotation.new(current_user, current_team, @query)
    render json: {
      res: [render_to_string(partial: 'shared/smart_annotation/experiment_items',
                             locals: { experiments: res.experiments },
                             formats: :html)],
      team: current_team.id
    }
  end

  def my_modules
    res = SmartAnnotation.new(current_user, current_team, @query)
    render json: {
      res: [render_to_string(partial: 'shared/smart_annotation/my_module_items',
                             locals: { my_modules: res.my_modules },
                             formats: :html)],
      team: current_team.id
    }
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
