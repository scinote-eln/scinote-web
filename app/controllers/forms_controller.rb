# frozen_string_literal: true

class FormsController < ApplicationController
  include UserRolesHelper

  before_action :load_form, only: %i(show update publish unpublish export_form_responses)
  before_action :set_breadcrumbs_items, only: %i(index show)
  before_action :check_manage_permissions, only: %i(update publish unpublish)
  before_action :check_create_permissions, only: :create

  def index
    respond_to do |format|
      format.html
      format.json do
        forms = Lists::FormsService.new(current_user, current_team, params).call
        render json: forms,
               each_serializer: Lists::FormSerializer,
               user: current_user,
               meta: pagination_dict(forms)
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @form, serializer: FormSerializer, include: %i(form_fields), user: current_user }
      format.html
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @form = Form.new(
        name: I18n.t('forms.default_name'),
        team: current_team,
        created_by: current_user,
        last_modified_by: current_user
      )

      if @form.save
        log_activity(@form, :form_created)
        render json: @form, serializer: FormSerializer, user: current_user
      else
        render json: { error: @form.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def update
    ActiveRecord::Base.transaction do
      if @form.update(form_params.merge({ last_modified_by: current_user }))
        log_activity(@form, :form_name_changed)
        render json: @form, serializer: FormSerializer, user: current_user
      else
        render json: { error: @form.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def published_forms
    forms = current_team.forms.readable_by_user(current_user).published
    forms = forms.where('forms.name ILIKE ?', "%#{params[:query]}%") if params[:query].present?
    forms = forms.page(params[:page])

    render json: {
      data: forms.map { |f| [f.id, f.name] },
      paginated: true,
      next_page: forms.next_page
    }
  end

  def publish
    ActiveRecord::Base.transaction do
      @form.update!(
        published_by: current_user,
        published_on: DateTime.now
      )
      log_activity(@form, :form_published, { version_number: 1 })

      render json: @form, serializer: FormSerializer, user: current_user
    end
  end

  def unpublish
    ActiveRecord::Base.transaction do
      @form.update!(
        published_by: nil,
        published_on: nil
      )

      render json: @form, serializer: FormSerializer, user: current_user
    end
  end

  def archive
    forms = current_team.forms.active.where(id: params[:form_ids])
    return render_404 if forms.blank?
    return render_403 unless forms.all? { |f| can_archive_form?(f) }

    counter = 0

    forms.each do |form|
      form.transaction do
        form.archive!(current_user)
        log_activity(form, :form_archived)
        counter += 1
      rescue StandardError => e
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end
    end

    if counter.positive?
      render json: { message: t('forms.archived.success_flash', number: counter) }
    else
      render json: { message: t('forms.archived.error_flash') }, status: :unprocessable_entity
    end
  end

  def restore
    forms = current_team.forms.archived.where(id: params[:form_ids])
    return render_404 if forms.blank?
    return render_403 unless forms.all? { |f| can_restore_form?(f) }

    counter = 0

    forms.each do |form|
      form.transaction do
        form.restore!(current_user)
        log_activity(form, :form_restored)
        counter += 1
      rescue StandardError => e
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end
    end

    if counter.positive?
      render json: { message: t('forms.restored.success_flash', number: counter) }
    else
      render json: { message: t('forms.restored.error_flash') }, status: :unprocessable_entity
    end
  end

  def export_form_responses
    FormResponsesZipExportJob.perform_later(
      user_id: current_user.id,
      params: {
        form_id: @form.id
      }
    )

    Activities::CreateActivityService.call(
      activity_type: :export_form_responses,
      owner: current_user,
      subject: @form,
      team: @form.team,
      message_items: {
        form: @form.id
      }
    )

    render json: { message: t('zip_export.export_request_success') }
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::FormsService.new(
          current_user,
          form_ids: JSON.parse(params[:items]).map { |i| i['id'] }
        ).actions
    }
  end

  def user_roles
    render json: { data: user_roles_collection(Form.new).map(&:reverse) }
  end

  private

  def set_breadcrumbs_items
    @breadcrumbs_items = []

    @breadcrumbs_items.push(
      { label: t('breadcrumbs.templates') }
    )

    @breadcrumbs_items.push(
      { label: t('breadcrumbs.forms'), url: forms_path }
    )

    if @form
      @breadcrumbs_items.push(
        { label: @form.name }
      )
    end
  end

  def load_form
    @form = current_team.forms.readable_by_user(current_user).find_by(id: params[:id])

    render_404 unless @form
  end

  def check_create_permissions
    render_403 unless can_create_forms?(current_team)
  end

  def check_manage_permissions

    render_403 unless @form && can_manage_form?(@form)
  end

  def form_params
    params.require(:form).permit(:name, :description)
  end

  def log_activity(form, type_of, message_items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: form.team,
            subject: form,
            message_items: {
              form: form.id,
              user: current_user.id
            }.merge(message_items))
  end
end
