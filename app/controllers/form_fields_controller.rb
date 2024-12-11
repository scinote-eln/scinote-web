# frozen_string_literal: true

class FormFieldsController < ApplicationController
  before_action :load_form
  before_action :load_form_field, only: %i(update destroy)

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
        render json: @form_field, serializer: FormFieldSerializer, user: current_user
      else
        render json: { error: @form_field.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def update
    ActiveRecord::Base.transaction do
      if @form_field.update(form_field_params.merge({ last_modified_by: current_user }))
        render json: @form_field, serializer: FormFieldSerializer, user: current_user
      else
        render json: { error: @form_field.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      if @form_field.discard
        render json: {}
      else
        render json: { error: @form_field.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def reorder
    ActiveRecord::Base.transaction do
      params.permit(form_field_positions: %i(position id))[:form_field_positions].each do |data|
        form_field = @form.form_fields.find(data[:id])
        form_field.insert_at(data[:position].to_i)
      end
    end

    render json: params[:form_field_positions], status: :ok
  rescue ActiveRecord::RecordInvalid
    render json: { errors: form_field.errors }, status: :conflict
  end

  private

  def load_form
    @form = Form.find_by(id: params[:form_id])

    return render_404 unless @form
  end

  def load_form_field
    @form_field = @form.form_fields.find_by(id: params[:id])

    return render_404 unless @form_field
  end

  def form_field_params
    params.require(:form_field).permit(:name, :description, { data: [%i(type options)] }, :required, :allow_not_applicable, :uid)
  end
end
