# frozen_string_literal: true

class StepResultsController < ApplicationController
  before_action :load_step, only: :create
  before_action :load_result, only: :create
  before_action :load_step_result, only: :destroy
  before_action :check_manage_permissions, only: %i(create destroy)

  def create
    ActiveRecord::Base.transaction do
      @step_result = StepResult.create!(step: @step, result: @result, created_by: current_user)
      render json: { step_result: { id: @step_result.id } }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
      render json: { errors: @step_result.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      if @step_result.destroy
        render json: {}, status: :ok
      else
        render json: { errors: @step_result.errors.full_messages }, status: :unprocessable_entity
      end
    end
    @step_result.destroy!
  end

  private

  def load_step
    @step = Step.find_by(id: params[:step_id])
    render_404 unless @step
  end

  def load_result
    @result = Result.find_by(id: params[:result_id])
    render_404 unless @result
  end

  def load_step_result
    @step_result = StepResult.find_by(id: params[:id])
    render_404 unless @step_result

    @step = @step_result.step
    @result = @step_result.result
  end

  def check_manage_permissions
    render_403 unless @step.my_module == @result.my_module && can_manage_my_module?(@step.my_module)
  end
end
