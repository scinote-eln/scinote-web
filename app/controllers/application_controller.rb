class ApplicationController < ActionController::Base
  acts_as_token_authentication_handler_for User
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true
  before_action :authenticate_user!
  helper_method :current_team
  before_action :update_current_team, if: :user_signed_in?
  before_action :set_date_format, if: :user_signed_in?
  around_action :set_time_zone, if: :current_user
  layout 'main'

  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_to root_path
  end

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

  def to_user_date_format
    ts = I18n.l(Time.parse(params[:timestamp]),
                format: params[:ts_format].to_sym)
    respond_to do |format|
      format.json do
        render json: { ts: ts }, status: :ok
      end
    end
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
      format.any do
        render plain: 'FORBIDDEN', status: :forbidden
      end
    end
  end

  def render_404
    respond_to do |format|
      format.html do
        render file: 'public/404.html', status: :not_found, layout: false
      end
      format.json do
        render json: {}, status: :not_found
      end
      format.any do
        render plain: 'NOT FOUND', status: :not_found
      end
    end
  end

  private

  def update_current_team
    current_team = Team.find_by_id(current_user.current_team_id)
    if (current_team.nil? || !current_user.is_member_of_team?(current_team)) &&
       current_user.teams.count.positive?

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

  def set_date_format
    I18n.backend.date_format =
      current_user.settings[:date_format] || Constants::DEFAULT_DATE_FORMAT
  end
end
