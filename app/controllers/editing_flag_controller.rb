# frozen_string_literal: true

class EditingFlagController < ApplicationController
  before_action :load_subject, only: %i(create index)
  before_action :load_editing_flag, only: %i(destroy refresh)
  before_action :check_manage_permission, only: %i(destroy refresh)

  def index
    editing_flags = EditingFlag.active.where(subject: @subject)
    render json: editing_flags, each_serializer: EditingFlagSerializer
  end

  def create
    @editing_flag = EditingFlag.find_or_initialize_by(user: current_user, subject: @subject)
    @editing_flag.timeout_at = EditingFlag::DEFAULT_DURATION.from_now
    @editing_flag.save!

    render json: @editing_flag, serializer: EditingFlagSerializer
  rescue ActiveRecord::RecordInvalid
    render json: { errors: @editing_flag.errors }, status: :unprocessable_entity
  end

  def refresh
    @editing_flag.update!(timeout_at: EditingFlag::DEFAULT_DURATION.from_now)

    render json: @editing_flag, serializer: EditingFlagSerializer
  rescue ActiveRecord::RecordInvalid
    render json: { errors: @editing_flag.errors }, status: :unprocessable_entity
  end

  def destroy
    @editing_flag.destroy
    render json: { message: :ok }
  end

  private

  def load_subject
    klass = params[:subject_type].to_s.safe_constantize
    return render_404 unless klass && klass < ActiveRecord::Base

    @subject = klass.find_by(id: params[:subject_id])
    render_404 unless @subject
  end

  def load_editing_flag
    @editing_flag = EditingFlag.find_by(id: params[:id])
    render_404 unless @editing_flag
  end

  def check_manage_permission
    render_403 unless @editing_flag && @editing_flag.user_id == current_user.id
  end
end
