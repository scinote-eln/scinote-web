class AtWhoController < ApplicationController
  include InputSanitizeHelper

  before_action :load_vars
  before_action :check_users_permissions

  def users
    respond_to do |format|
      format.json do
        render json: {
          users: generate_users_data,
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
          sam: res.samples,
          status: :ok
        }
      end
    end
  end

  def rep_items
    repository = Repository.find_by_id(params[:repository_id])
    items =
      if repository && can_read_repository?(repository)
        SmartAnnotation.new(current_user, current_team, @query)
                       .repository_rows(repository)
      else
        []
      end
    respond_to do |format|
      format.json do
        render json: {
          res: items,
          status: :ok
        }
      end
    end
  end

  def repositories
    repositories = Repository.accessible_by_teams(@team)
    respond_to do |format|
      format.json do
        render json: {
          repositories: repositories.map do |r|
            [r.id, escape_input(r.name.truncate(Constants::ATWHO_REP_NAME_LIMIT))]
          end.to_h,
          status: :ok
        }
      end
    end
  end

  def projects
    res = SmartAnnotation.new(current_user, current_team, @query)
    respond_to do |format|
      format.json do
        render json: {
          res: res.projects,
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
          res: res.experiments,
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
          res: res.my_modules,
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

  def generate_users_data
    # Search users
    res = @team.search_users(@query)
               .limit(Constants::ATWHO_SEARCH_LIMIT)
               .pluck(:id, :full_name, :email)

    # Add avatars, Base62, convert to JSON
    data = []
    res.each do |obj|
      tmp = {}
      tmp['id'] = obj[0].base62_encode
      tmp['full_name'] = escape_input(obj[1].truncate(Constants::NAME_TRUNCATION_LENGTH_DROPDOWN))
      tmp['email'] = escape_input(obj[2])
      tmp['img_url'] = avatar_path(obj[0], :icon_small)
      data << tmp
    end
    data
  end
end
