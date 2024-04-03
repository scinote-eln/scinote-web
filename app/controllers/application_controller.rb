class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true
  before_action :authenticate_user!
  helper_method :current_team
  before_action :update_current_team, if: :user_signed_in?
  around_action :set_date_format, if: :user_signed_in?
  around_action :set_time_zone, if: :current_user
  layout 'main'

  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_to root_path
  end

  def forbidden
    render_403
  end

  def not_found
    render_404
  end

  def respond_422(message = t('client_api.permission_error'))
    render_422(message)
  end

  def is_current_page_root?
    controller_name == 'projects' && action_name == 'index'
  end

  # Sets current team for all controllers
  def current_team
    @current_team ||= current_user.teams.find_by(id: current_user.current_team_id)
  end

  def to_user_date_format
    ts = I18n.l(Time.parse(params[:timestamp]),
                format: params[:ts_format].to_sym)

    render json: { ts: ts }, status: :ok
  end

  protected

  def render_403(style = 'danger')
    respond_to do |format|
      format.html do
        render 'errors/403', status: :forbidden, layout: false
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
        render 'errors/404', status: :not_found, layout: false
      end
      format.json do
        render json: {}, status: :not_found
      end
      format.any do
        render plain: 'NOT FOUND', status: :not_found
      end
    end
  end

  def render_422(message = t('client_api.permission_error'))
    respond_to do |format|
      format.html do
        render 'errors/422', status: :unprocessable_entity, layout: false
      end
      format.json do
        render json: { message: message }, status: :unprocessable_entity
      end
      format.any do
        render plain: 'UNPROCESSABLE ENTITY', status: :unprocessable_entity
      end
    end
  end

  private

  def update_current_team
    return if current_team.present? && current_team.id == current_user.current_team_id

    if current_user.current_team_id
      @current_team = current_user.teams.find_by(id: current_user.current_team_id)
    elsif current_user.teams.any?
      current_user.update(current_team_id: current_user.teams.first.id)
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
    I18n.backend.date_format = current_user.settings[:date_format]
    yield
  ensure
    I18n.backend.date_format = nil
  end

  def pagination_dict(object)
    {
      current_page: object.current_page,
      next_page: object.next_page,
      prev_page: object.prev_page,
      total_pages: object.total_pages,
      total_count: object.total_count
    }
  end
end
