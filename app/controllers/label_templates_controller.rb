# frozen_string_literal: true

class LabelTemplatesController < ApplicationController
  include InputSanitizeHelper

  before_action :check_feature_enabled
  before_action :check_view_permissions, only: %i(index datatable)
  before_action :check_manage_permissions, only: %i(create duplicate set_default delete update)
  before_action :load_label_templates, only: %i(index datatable)
  before_action :load_label_template, only: %i(show set_default update)

  layout 'fluid'

  def index; end

  def datatable
    respond_to do |format|
      format.json do
        render json: ::LabelTemplateDatatable.new(
          view_context,
          can_manage_label_templates?(current_team),
          @label_templates
        )
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @label_template, serializer: LabelTemplateSerializer, user: current_user }
      format.html
    end
  end

  def create
    label_template = ZebraLabelTemplate.default.save!

    redirect_to label_template_path(label_template, new_label: true)
  end

  def update
    if @label_template.update(label_template_params)
      render json: @label_template, serializer: LabelTemplateSerializer, user: current_user
    else
      render json: { error: @label_template.errors.messages }, status: :unprocessable_entity
    end
  end

  def duplicate
    ActiveRecord::Base.transaction do
      LabelTemplate.where(team_id: current_team.id, id: params[:selected_ids]).each do |template|
        new_template = template.dup
        new_template.default = false
        new_template.name = template.name + '(1)'
        new_template.save!
      end
      render json: { message: I18n.t('label_templates.index.templates_duplicated',
                                     count: params[:selected_ids].length) }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
      render json: { error: I18n.t('errors.general') }, status: :unprocessable_entity
    end
  end

  def delete
    ActiveRecord::Base.transaction do
      LabelTemplate.where(team_id: current_team.id, id: params[:selected_ids]).each(&:destroy!)
      render json: { message: I18n.t('label_templates.index.templates_deleted') }
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    Rails.logger.error e.message
    render json: { error: I18n.t('errors.general') }, status: :unprocessable_entity
  end

  def set_default
    ActiveRecord::Base.transaction do
      LabelTemplate.find_by(team_id: current_team.id,
                            type: @label_template.type,
                            default: true)&.update!(default: false)
      @label_template.update!(default: true)
      render json: { message: I18n.t('label_templates.index.template_set_as_default') }
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
    render json: { error: I18n.t('errors.general') }, status: :unprocessable_entity
  end

  private

  def check_feature_enabled
    render :promo unless LabelTemplate.enabled?
  end

  def check_view_permissions
    render_403 unless can_view_label_templates?(current_team)
  end

  def check_manage_permissions
    render_403 unless can_manage_label_templates?(current_team)
  end

  def load_label_templates
    @label_templates = LabelTemplate.where(team_id: current_team.id)
  end

  def load_label_template
    @label_template = LabelTemplate.where(team_id: current_team.id).find(params[:id])
  end

  def label_template_params
    params.require(:label_template).permit(:name, :description, :content)
  end
end
