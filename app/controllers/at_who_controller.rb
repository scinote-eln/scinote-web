class AtWhoController < ApplicationController
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

  def samples
    res = SmartAnnotation.new(current_user, current_team, @query)
    respond_to do |format|
      format.json do
        render json: {
          res: res.samples,
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
    render_403 unless can_view_team_users(@team)
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
      tmp['full_name'] = obj[1]
                           .truncate(Constants::NAME_TRUNCATION_LENGTH_DROPDOWN)
      tmp['email'] = obj[2]
      tmp['img_url'] =  avatar_path(obj[0], :icon_small)
      data << tmp
    end
    data
  end
end
