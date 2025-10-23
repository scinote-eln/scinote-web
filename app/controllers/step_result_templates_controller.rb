# frozen_string_literal: true

class StepResultTemplatesController < ApplicationController
  before_action :load_steps
  before_action :load_result_templates
  before_action :load_step_result_templates
  before_action :check_manage_permissions

  def link_results
    ActiveRecord::Base.transaction do
      @step_result_templates.where.not(result_template: @result_templates).each do |step_result_template|
        step_result_template.destroy!
      end
      @result_templates.where.not(id: @step_result_templates.select(:result_template_id)).each do |result_template|
        StepResultTemplate.create!(step: @steps.first, result_template: result_template, created_by: current_user)
      end
      render json: { results: @steps.first.result_templates.map { |r| { id: r.id, name: r.name } } }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
      render json: { message: :error }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def link_steps
    ActiveRecord::Base.transaction do
      @step_result_templates.where.not(step: @steps).each do |step_result_template|
        step_result_template.destroy!
      end
      @steps.where.not(id: @step_result_templates.select(:step_id)).each do |step|
        StepResultTemplate.create!(step: step, result_template: @result_templates.first, created_by: current_user)
      end
      render json: { steps: @result_templates.first.steps.map { |s| { id: s.id, name: s.label } } }, status: :created
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

  def load_result_templates
    @result_templates = ResultTemplate.where(id: params[:result_ids])

    render_404 and return if (action_name == 'link_steps') && @result_templates.size != 1

    render_403 and return if @result_templates.pluck(:protocol_id).uniq.size > 1
  end

  def load_step_result_templates
    @step_result_templates = StepResultTemplate.where(step: @steps) if action_name == 'link_results'
    @step_result_templates = StepResultTemplate.where(result_template: @result_templates) if action_name == 'link_steps'
  end

  def check_manage_permissions
    case action_name
    when 'link_results'
      render_403 and return unless can_manage_protocol_draft_in_repository?(@steps.first.protocol)
    when 'link_steps'
      render_403 and return unless can_manage_protocol_draft_in_repository?(@result_templates.first.protocol)
    end

    render_403 and return unless (@result_templates + @steps).map(&:protocol).uniq.one?
  end
end
