# frozen_string_literal: true

class EquipmentBookingsController < ApplicationController
  before_action :check_calendar_events_enabled
  before_action :set_breadcrumbs_items, only: :index
  before_action :load_repository, only: %i(assigned_repository_rows assigned_users)

  def index; end

  def assigned_repository_rows
    repository_rows = @repository.repository_rows
    if params[:query].present?
      repository_rows = repository_rows.where_attributes_like(
        ['repository_rows.name', RepositoryRow::PREFIXED_ID_SQL],
        params[:query]
      )
    end
    repository_rows = repository_rows.active

    # In next tickets it will be filtered by assigned items to events

    repository_rows = repository_rows.order('LOWER(repository_rows.name) asc').page(params[:page])

    render json: {
      paginated: true,
      next_page: repository_rows.next_page,
      data: repository_rows.map { |r| [r.id, r.name] }
    }
  end

  def assigned_users
    calendar_events = User.joins(:calendar_events)
                          .joins("INNER JOIN repository_rows ON
                                  repository_rows.id = calendar_events.subject_id AND
                                  calendar_events.subject_type = 'RepositoryRow' AND
                                  repository_rows.archived = false")
                          .where(repository_rows: { repository_id: @repository.id })

    repository_users = @repository.users_with_permission(RepositoryPermissions::READ, current_team)

    users = case params[:mode]
            when 'repository_only'
              repository_users
            when 'assigned_only'
              calendar_events
            else
              User.where(id: repository_users.select(:id)).or(User.where(id: calendar_events.select(:id))).distinct
            end

    users = users.search(false, params[:query]).map do |u|
      [u.id, u.name, { avatar_url: avatar_path(u, :icon_small) }]
    end

    render json: { data: users }, status: :ok
  end

  private

  def check_calendar_events_enabled
    render :promo unless Repository.equipment_booking_enabled?
  end

  def set_breadcrumbs_items
    @breadcrumbs_items = [
      { label: t('breadcrumbs.equipment_bookings'), url: nil }
    ]
  end

  def load_repository
    @repository = Repository.find_by(id: params[:repository_id])

    render_404 and return unless @repository
    render_403 and return unless can_read_repository?(@repository)
  end
end
