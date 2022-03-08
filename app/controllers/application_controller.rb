class ApplicationController < ActionController::Base
  include PermissionHelper
  include FirstTimeDataGenerator

  acts_as_token_authentication_handler_for User
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true
  before_action :authenticate_user!
  helper_method :current_team
  before_action :generate_intro_tutorial, if: :is_current_page_root?
  before_action :update_current_team, if: :user_signed_in?
  around_action :set_time_zone, if: :current_user
  layout 'main'

  def respond_422(message = t('client_api.permission_error'))
    respond_to do |format|
      format.json do
        render json: { message: message },
               status: 422
      end
    end
  end

  def forbidden
    render_403
  end

  def not_found
    render_404
  end

  def is_current_page_root?
    controller_name == 'projects' && action_name == 'index'
  end

  # Sets current team for all controllers
  def current_team
    Team.find_by_id(current_user.current_team_id)
  end

  protected

  def render_403(style = 'danger')
    respond_to do |format|
      format.html do
        render file: 'public/403.html', status: :forbidden, layout: false
      end
      format.json do
        render json: { style: style }, status: :forbidden
      end
    end
    true
  end

  def render_404
    respond_to do |format|
      format.html {
        render :file => 'public/404.html', :status => :not_found, :layout => false
      }
      format.json {
        render json: {}, status: :not_found
      }
    end
    return true
  end

  private

  def generate_intro_tutorial
    if Rails.configuration.x.enable_tutorial &&
      current_user.no_tutorial_done? &&
      current_user.teams.where(created_by: current_user).count > 0 then
      demo_cookie = seed_demo_data current_user
      cookies[:tutorial_data] = {
        value: demo_cookie,
        expires: 1.week.from_now
      }
      current_user.update(tutorial_status: 1)
    end
  end

  def update_current_team
    if current_user.current_team_id.blank? &&
       current_user.teams.count > 0
      current_user.update(
        current_team_id: current_user.teams.first.id
      )
    end
  end

  # With this Devise callback user is redirected directly to sign in page instead
  # of to root path. Therefore notification for sign out is displayed.
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def set_time_zone(&block)
    Time.use_zone(current_user.settings[:time_zone], &block)
  end
end
