class CustomFieldsController < ApplicationController
  before_action :load_vars, only: :update
  before_action :load_vars_nested, only: [:create]
  before_action :check_create_permissions, only: [:create]
  before_action :check_update_permissions, only: :update

  def create
    @custom_field = CustomField.new(custom_field_params)
    @custom_field.organization = @organization
    @custom_field.user = current_user

    respond_to do |format|
      if @custom_field.save
        format.json do
          render json: {
            id: @custom_field.id,
            name: @custom_field.name
          },
          status: :ok
        end
      else
        format.json do
          render json: @custom_field.errors.to_json,
                 status: :unprocessable_entity
        end
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        @custom_field.update_attributes(custom_field_params)
        if @custom_field.save
          render json: { status: :ok }
        else
          render json: @custom_field.errors.to_json,
                 status: :unprocessable_entity
        end
      end
    end
  end

  private

  def load_vars
    @custom_field = CustomField.find_by_id(params[:id])
    render_404 unless @custom_field
  end

  def load_vars_nested
    @organization = Organization.find_by_id(params[:organization_id])
    render_404 unless @organization
  end

  def check_create_permissions
    render_403 unless can_create_custom_field_in_organization(@organization)
  end

  def check_update_permissions
    render_403 unless can_edit_custom_field(@custom_field)
  end

  def custom_field_params
    params.require(:custom_field).permit(:name)
  end
end
