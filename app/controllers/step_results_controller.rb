# frozen_string_literal: true

class StepResultsController < ApplicationController
  before_action :load_steps
  before_action :load_results
  before_action :load_step_results
  before_action :check_manage_permissions

  def link_results
    ActiveRecord::Base.transaction do
      @step_results.where.not(result: @results).each do |step_result|
        log_activity(:step_and_result_unlinked, step_result.step.my_module, step_result.step, step_result.result)
        step_result.destroy!
      end
      @results.where.not(id: @step_results.select(:result_id)).each do |result|
        StepResult.create!(step: @steps.first, result: result, created_by: current_user)
        log_activity(:step_and_result_linked, @steps.first.my_module, @steps.first, result)
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
        log_activity(:step_and_result_unlinked, step_result.result.my_module, step_result.step, step_result.result)
        step_result.destroy!
      end
      @steps.where.not(id: @step_results.select(:step_id)).each do |step|
        StepResult.create!(step: step, result: @results.first, created_by: current_user)
        log_activity(:step_and_result_linked, @results.first.my_module, step, @results.first)
      end
      render json: { steps: @results.first.steps.map { |s| { id: s.id, name: s.name } } }, status: :created
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
    @results = Result.where(id: params[:result_ids])

    render_404 and return if (action_name == 'link_steps') && @results.size != 1

    render_403 and return if @results.pluck(:my_module_id).uniq.size > 1
  end

  def load_step_results
    @step_results = StepResult.where(step: @steps) if action_name == 'link_results'
    @step_results = StepResult.where(result: @results) if action_name == 'link_steps'
  end

  def check_manage_permissions
    case action_name
    when 'link_results'
      render_403 and return unless can_manage_my_module?(@steps.first.my_module)
    when 'link_steps'
      render_403 and return unless can_manage_my_module?(@results.first.my_module)
    end

    render_403 and return unless (@results + @steps).map(&:my_module).uniq.one?
  end

  def log_activity(type_of, my_module, step, result)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: my_module,
            team: my_module.team,
            project: my_module.experiment.project,
            message_items: {
              my_module: my_module.id,
              step: step.id,
              result: result.id,
              step_position: { id: step.id,
                               value_for: 'position_plus_one' }
            })
  end
end
