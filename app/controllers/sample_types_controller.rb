class SampleTypesController < ApplicationController
  before_action :load_vars_nested, only: [:create]
  before_action :check_create_permissions, only: [:create]

  def create
    @sample_type = SampleType.new(sample_type_params)
    @sample_type.organization = @organization
    @sample_type.created_by = current_user
    @sample_type.last_modified_by = current_user

    respond_to do |format|
      if @sample_type.save
        format.json {
          render json: {
            id: @sample_type.id,
            flash: t(
              'sample_types.create.success_flash',
              sample_type: @sample_type.name,
              organization: @organization.name
            )
          },
          status: :ok
        }
      else
        format.json {
          render json: @sample_type.errors,
            status: :unprocessable_entity
        }
      end
    end
  end

  def index
    render_404 unless current_organization
    @sample_types = current_organization.sample_types
  end

  private

  def load_vars_nested
    @organization = Organization.find_by_id(params[:organization_id])

    unless @organization
      render_404
    end
  end

  def check_create_permissions
    unless can_create_sample_type_in_organization(@organization)
      render_403
    end
  end

  def sample_type_params
    params.require(:sample_type).permit(:name)
  end
end
