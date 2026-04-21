# frozen_string_literal: true

class CalendarEventParticipantsController < ApplicationController
  before_action :load_calendar_event
  before_action :load_calendar_event_participant, only: :destroy
  before_action :check_read_permission, only: :index
  before_action :check_manage_permission, except: :index

  def index
    respond_to do |format|
      format.json do
        render json: @calendar_event.calendar_event_participants,
               each_serializer: CalendarEventParticipantSerializer
      end
    end
  end

  def create
    ActiveRecord::Base.transaction do
      user = current_team.users.find(params[:user_id])
      calendar_event_participant = @calendar_event.calendar_event_participants.create!(user: user)

      render json: calendar_event_participant,
             serializer: CalendarEventParticipantSerializer
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      @calendar_event_participant.destroy!
      render json: { message: :ok }
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  private

  def load_calendar_event
    @calendar_event = CalendarEvent.find_by(id: params[:calendar_event_id])
    render_404 unless @calendar_event
  end

  def load_calendar_event_participant
    @calendar_event_participant = @calendar_event.calendar_event_participants.find_by(id: params[:id])
    render_404 unless @calendar_event_participant
  end

  def check_read_permission; end

  def check_manage_permission; end
end
