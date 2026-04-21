# frozen_string_literal: true

class CalendarEventsController < ApplicationController
  before_action :load_calendar_event, except: %i(index create)
  before_action :load_repository_row, only: :create
  before_action :check_read_permission, only: %i(index show)
  before_action :check_manage_permission, except: %i(index show)

  def index
    calendar_events = current_team.calendar_events.where(event_type: params[:event_type])
    respond_to do |format|
      format.json do
        render json: calendar_events,
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
    @calendar_event = CalendarEvent.new(calendar_event_params)
    @calendar_event.team = current_team
    @calendar_event.subject = @repository_row
    @calendar_event.created_by = current_user

    if @calendar_event.save
      render json: @calendar_event, serializer: CalendarEventSerializer, user: current_user
    else
      render json: { errors: @calendar_event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @calendar_event.update(calendar_event_params)
      render json: @calendar_event, serializer: CalendarEventSerializer, user: current_user
    else
      render json: { errors: @calendar_event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      @calendar_event.destroy!
      render json: { message: :ok }
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  private

  def load_calendar_event
    @calendar_event = CalendarEvent.find_by(id: params[:id])
    render_404 unless @calendar_event
  end

  def load_repository_row
    @repository_row = RepositoryRow.find_by(id: params[:repository_row_id])

    render_404 unless @repository_row
  end

  def calendar_event_params
    params.permit(%i(start_at end_at event_type metadata:{}))
  end

  def check_read_permission; end

  def check_manage_permission; end
end
