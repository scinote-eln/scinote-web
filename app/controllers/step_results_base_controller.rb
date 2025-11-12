# frozen_string_literal: true

class StepResultsBaseController < ApplicationController
  before_action :load_steps
  before_action :load_results
  before_action :load_step_results
  before_action :check_manage_permissions

  def link_results
    ActiveRecord::Base.transaction do
      @step_results.where.not(result: @results).each do |step_result|
        log_activity(:"step_and_#{step_result.result.class.model_name.param_key}_unlinked", step_result.step, step_result.result)
        step_result.destroy!
      end
      @results.where.not(id: @step_results.select(:result_id)).each do |result|
        StepResult.create!(step: @steps.first, result_id: result.id, created_by: current_user)
        log_activity(:"step_and_#{result.class.model_name.param_key}_linked", @steps.first, result)
      end
      render json: { results: @steps.first.results.map { |r| { id: r.id, name: r.name, archived: r.archived? } } }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
      render json: { message: :error }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def link_steps
    ActiveRecord::Base.transaction do
      @step_results.where.not(step: @steps).each do |step_result|
        log_activity(:"step_and_#{step_result.result.class.model_name.param_key}_unlinked", step_result.step, step_result.result)
        step_result.destroy!
      end
      @steps.where.not(id: @step_results.select(:step_id)).each do |step|
        StepResult.create!(step: step, result_id: @results.first.id, created_by: current_user)
        log_activity(:"step_and_#{@results.first.class.model_name.param_key}_linked", step, @results.first)
      end
      render json: { steps: @results.first.steps.map { |s| { id: s.id, name: s.label } } }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
      render json: { message: :error }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  private

  def load_steps
    @steps = Step.where(id: params[:step_ids])

    render_404 and return if (action_name == 'link_results') && @steps.size != 1

    render_403 and return if @steps.pluck(:protocol_id).uniq.size > 1
  end

  def load_results
    # To be defined in subclasses
  end

  def load_step_results
    @step_results = StepResult.where(step: @steps) if action_name == 'link_results'
    @step_results = StepResult.where(result: @results) if action_name == 'link_steps'
  end

  def check_manage_permissions
    false # To be defined in subclasses
  end

  def log_activity(type_of, step, result)
    parent = result.parent
    message_items = { "#{parent.class.model_name.param_key}": parent.id,
                      step: step.id,
                      "#{result.class.model_name.param_key}": result.id }
    message_items[:step_position] = { id: step.id, value_for: 'position_plus_one' } if parent.is_a?(MyModule)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: parent,
            team: parent.team,
            project: nil,
            message_items: message_items)
  end
end
