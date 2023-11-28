# frozen_string_literal: true

class LabelTemplatesController < ApplicationController
  include InputSanitizeHelper
  include TeamsHelper

  before_action :check_feature_enabled, except: %i(index zpl_preview)
  before_action :load_label_templates, only: %i(index datatable)
  before_action :load_label_template, only: %i(show set_default update template_tags)
  before_action :check_view_permissions, except: %i(create duplicate set_default delete update)
  before_action :check_manage_permissions, only: %i(create duplicate set_default delete update)
  before_action :set_breadcrumbs_items, only: %i(index show)

  layout 'fluid'

  def index
    respond_to do |format|
      format.json do
        label_templates = Lists::LabelTemplatesService.new(@label_templates, params).call
        render json: label_templates, each_serializer: Lists::LabelTemplateSerializer, user: current_user, meta: pagination_dict(label_templates)
      end
      format.html do
        unless LabelTemplate.enabled?
          render :promo
          return
        end
        render 'index'
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
    ActiveRecord::Base.transaction do
      label_template = ZebraLabelTemplate.default
      label_template.team = current_team
      label_template.created_by = current_user
      label_template.last_modified_by = current_user
      label_template.save!
      log_activity(:label_template_created, label_template)
      render json: { redirect_url: label_template_path(label_template, new_label: true) }
    end
  rescue StandardError => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
  end

  def update
    @label_template.transaction do
      update_label_template_params = label_template_params.merge(last_modified_by_id: current_user.id)
      @label_template.update!(update_label_template_params)
      log_activity(:label_template_edited, @label_template)
    end
    render json: @label_template, serializer: LabelTemplateSerializer, user: current_user
  rescue StandardError => e
    Rails.logger.error e.message
    render json: { error: @label_template.errors.messages }, status: :unprocessable_entity
  end

  def duplicate
    ActiveRecord::Base.transaction do
      LabelTemplate.where(team_id: current_team.id, id: params[:selected_ids]).each do |template|
        new_template = template.dup
        new_template.default = false
        new_template.created_by = current_user
        new_template.last_modified_by = current_user
        new_template.name = template.name + '(1)'
        new_template.save!
        log_activity(
          :label_template_copied,
          new_template,
          message_items: { label_template_new: new_template.id, label_template_original: template.id }
        )
      end
      render json: { message: I18n.t('label_templates.index.templates_duplicated',
                                     count: params[:selected_ids].length) }
    end
  rescue StandardError => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { error: I18n.t('errors.general') }, status: :unprocessable_entity
  end

  def delete
    ActiveRecord::Base.transaction do
      LabelTemplate.where(team_id: current_team.id, id: params[:selected_ids]).each do |template|
        log_activity(:label_template_deleted, template)
        template.destroy!
      end
      render json: { message: I18n.t('label_templates.index.templates_deleted') }
    end
  rescue StandardError => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
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
  rescue StandardError => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { error: I18n.t('errors.general') }, status: :unprocessable_entity
  end

  def template_tags
    render json: LabelTemplates::TagService.new(current_team, @label_template).tags
  end

  def zpl_preview
    service = LabelTemplatesPreviewService.new(params, current_user)

    # only render last generated label image
    payload = service.generate_zpl_preview!.split.last

    if service.error.blank? && payload.present?
      render json: { base64_preview: payload }
    else
      render json: { error: service.error }, status: :unprocessable_entity
    end
  end

  def sync_fluics_templates
    sync_service = LabelPrinters::Fluics::SyncService.new(current_user, current_team)
    sync_service.sync_templates!
    render json: { message: t('label_templates.fluics.sync.success') }
  rescue StandardError => e
    Rails.logger.error e.message
    render json: { error: t('label_templates.fluics.sync.error') }, status: :unprocessable_entity
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::LabelTemplatesService.new(
          current_user,
          label_template_ids: JSON.parse(params[:items]).map { |i| i['id'] }
        ).actions
    }
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
    @label_templates = LabelTemplate.enabled? ? current_team.label_templates : current_team.label_templates.default
  end

  def load_label_template
    @label_template = LabelTemplate.find(params[:id])

    current_team_switch(@label_template.team) if current_team != @label_template.team
  end

  def label_template_params
    params.require(:label_template).permit(:name, :description, :content, :width_mm, :height_mm, :unit, :density)
  end

  def log_activity(type_of, label_template = @label_template, message_items: {})
    message_items = { label_template: label_template.id } if message_items.blank?
    message_items[:type] = I18n.t("label_templates.types.#{label_template.class.name.underscore}")
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: label_template,
            team: label_template.team,
            message_items: message_items)
  end

  def set_breadcrumbs_items
    @breadcrumbs_items = []

    @breadcrumbs_items.push({
                              label: t('breadcrumbs.templates'),
                            })

    @breadcrumbs_items.push({
                              label: t('breadcrumbs.labels'),
                              url: label_templates_path
                            })
    if @label_template
      @breadcrumbs_items.push({
                                label: @label_template.name,
                                url: label_template_path(@label_template)
                              })
    end
  end
end
