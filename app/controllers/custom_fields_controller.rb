class CustomFieldsController < ApplicationController
  before_action :load_vars_nested, only: [:create]
  before_action :check_create_permissions, only: [:create]

  def create
    @custom_field = CustomField.new(custom_field_params)
    @custom_field.organization = @organization
    @custom_field.user = current_user

    respond_to do |format|
      if @custom_field.save
        flash[:success] = t(
          "custom_fields.create.success_flash",
          custom_field: @custom_field.name,
          organization: @organization.name
          )
        format.json {
          render json: {
            id: @custom_field.id
          },
          status: :ok }
      else
        format.json do
          render json: @custom_field.errors.to_json,
                 status: :unprocessable_entity
        end
      end
    end
  end

  private

  def load_vars_nested
    @organization = Organization.find_by_id(params[:organization_id])

    unless @organization
      render_404
    end
  end

  def check_create_permissions
    unless can_create_custom_field_in_organization(@organization)
      render_403
    end
  end

  def custom_field_params
    params.require(:custom_field).permit(:name)
  end
end
