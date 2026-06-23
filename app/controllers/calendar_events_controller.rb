# frozen_string_literal: true

class CalendarEventsController < ApplicationController
  before_action :check_calendar_events_enabled
  before_action :load_parent, only: :index
  before_action :load_subject, only: %i(create update)
  before_action :load_calendar_event, except: %i(index create)
  before_action :check_read_permission, only: :show
  before_action :check_manage_permission, except: %i(index show create)
  before_action :check_create_permission, only: :create

  def index
    @calendar_events = CalendarEvent.where(team_id: current_user.teams.select(:id))
                                    .where(event_type: params[:event_type])

    filter_calendar_events!

    respond_to do |format|
      format.json do
        render json: @calendar_events,
               each_serializer: CalendarEventSerializer
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @calendar_event,
               each_serializer: CalendarEventSerializer
      end
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @calendar_event = CalendarEvent.create!(calendar_event_params.merge(
        team: current_team,
        subject: @subject,
        created_by: current_user
      ))
      log_activity(@calendar_event, :calendar_event_created)
      calendar_event_params[:user_ids]&.each do |user_id|
        log_activity(@calendar_event, :calendar_event_participant_created, { user_target: user_id })
      end
    end


    render json: @calendar_event, serializer: CalendarEventSerializer, user: current_user
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
    render json: { errors: e.message }, status: :unprocessable_entity
  end

  def update
    participant_ids = Array(calendar_event_params[:user_ids])
    current_participant_ids = @calendar_event.user_ids
    removed_ids = current_participant_ids - participant_ids
    new_ids = participant_ids - current_participant_ids

    ActiveRecord::Base.transaction do
      @calendar_event.update!(calendar_event_params.merge(subject: @subject))

      log_activity(@calendar_event, :calendar_event_updated) if @calendar_event.saved_changes?
      new_ids.each { |user_id| log_activity(@calendar_event, :calendar_event_participant_created, { user_target: user_id }) }
      removed_ids.each { |user_id| log_activity(@calendar_event, :calendar_event_participant_deleted, { user_target: user_id }) }
    end

    render json: @calendar_event, serializer: CalendarEventSerializer, user: current_user
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
    render json: { errors: e.message }, status: :unprocessable_entity
  end

  def destroy
    ActiveRecord::Base.transaction do
      log_activity(@calendar_event, :calendar_event_deleted, { participant_user_ids: @calendar_event.user_ids.join(',') })

      @calendar_event.destroy!
      render json: { message: :ok }
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  private

  def check_calendar_events_enabled
    render_404 unless Repository.equipment_booking_enabled?
  end

  def load_calendar_event
    @calendar_event = CalendarEvent.find_by(id: params[:id])
    render_404 unless @calendar_event
  end

  def load_parent
    @parent = case params[:parent_type]
              when 'Repository'
                @parent = Repository.readable_by_user(current_user).find(params[:parent_id])
              else
                raise NotImplementedError
              end
  end

  def load_subject
    case params[:subject_type]
    when 'RepositoryRow'
      @subject = RepositoryRow.find(params[:subject_id])
    else
      raise NotImplementedError
    end
  end

  def calendar_event_params
    if params[:start_date].present? && params[:end_date].present?
      params[:start_datetime] = nil
      params[:end_datetime] = nil
    else
      params[:start_date] = nil
      params[:end_date] = nil
    end

    params.permit(
      :name,
      :start_datetime,
      :start_date,
      :end_datetime,
      :end_date,
      :event_type,
      :event_sub_type,
      user_ids: [],
      metadata: {}
    )
  end

  def check_read_permission
    case @calendar_event.subject_type
    when 'RepositoryRow'
      render_403 unless can_read_equipment_bookings?(@calendar_event.subject.repository)
    else
      raise NotImplementedError
    end
  end

  def check_create_permission
    case @subject
    when RepositoryRow
      render_403 unless can_create_equipment_bookings?(@subject.repository)
    else
      raise NotImplementedError
    end
  end

  def check_manage_permission
    case @calendar_event.subject_type
    when 'RepositoryRow'
      render_403 unless can_manage_equipment_bookings?(@calendar_event.subject.repository)
    else
      raise NotImplementedError
    end
  end

  def log_activity(calendar_event, type_of, message_items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: calendar_event.team,
            subject: calendar_event.subject,
            message_items: {
              event: calendar_event.name,
              repository_row: calendar_event.subject.id,
              calendar_event_id: calendar_event.id
            }.merge(message_items))
  end

  def filter_calendar_events!
    if @parent.is_a?(Repository) # Repository related filters
      @calendar_events = @calendar_events.repository_filter(@parent.id)
      @calendar_events = @calendar_events.repository_rows_filter(params[:filters][:subject_ids]) if params.dig(:filters, :subject_ids).present?
    end

    # General filters
    if params.dig(:filters, :sub_types).present?
      selected_sub_types = params[:filters][:sub_types].select { |_, v| v == 'true' }.keys
      @calendar_events = @calendar_events.event_sub_type_filter(selected_sub_types)
    end
    @calendar_events = @calendar_events.datetime_filter(params[:start_date], params[:end_date]) if params[:start_date].present? && params[:end_date].present?
    @calendar_events = @calendar_events.assigned_users_filter(params[:filters][:assigned_user_ids]) if params.dig(:filters, :assigned_user_ids).present?
  end
end
