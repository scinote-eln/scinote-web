# frozen_string_literal: true

class FormFieldsController < ApplicationController
  before_action :load_form
  before_action :load_form_field, only: %i(update destroy)
  before_action :check_manage_permissions, only: %i(create update destroy reorder)

  def create
    ActiveRecord::Base.transaction do
      @form_field = FormField.new(
        form_field_params.merge(
          {
            form: @form,
            created_by: current_user,
            last_modified_by: current_user,
            position: @form.form_fields.length
          }
        )
      )

      if @form_field.save
        log_activity(:form_block_added, block_name: @form_field.name)
        render json: @form_field, serializer: FormFieldSerializer, user: current_user
      else
        render json: { error: @form_field.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def update
    ActiveRecord::Base.transaction do
      if @form_field.update(form_field_params.merge({ last_modified_by: current_user }))
        log_activity(:form_block_edited, block_name: @form_field.name)
        render json: @form_field, serializer: FormFieldSerializer, user: current_user
      else
        render json: { error: @form_field.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      if @form_field.destroy
        log_activity(:form_block_deleted, block_name: @form_field.name)
        render json: {}
      else
        render json: { error: @form_field.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def reorder
    ActiveRecord::Base.transaction do
      params.permit(form_field_positions: %i(position id))[:form_field_positions].each do |data|
        @form_field = @form.form_fields.find(data[:id])
        @form_field.insert_at!(data[:position].to_i)
      end
      log_activity(:form_block_rearranged)
    end

    render json: params[:form_field_positions], status: :ok
  rescue ActiveRecord::RecordInvalid
    render json: { errors: @form_field.errors }, status: :unprocessable_entity
  end

  private

  def load_form
    @form = Form.find_by(id: params[:form_id])

    render_404 unless @form
  end

  def load_form_field
    @form_field = @form.form_fields.find_by(id: params[:id])

    render_404 unless @form_field
  end

  def check_manage_permissions
    render_403 unless @form && can_manage_form?(@form)
  end

  def form_field_params
    params.require(:form_field).permit(:name, :description, { data: [:type, :unit, :time, :range, validations: {}, options: []] }, :required, :allow_not_applicable, :uid)
  end

  def log_activity(type_of, message_items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: @form.team,
            subject: @form,
            message_items: {
              form: @form.id,
              user: current_user.id
            }.merge(message_items))
  end
end
