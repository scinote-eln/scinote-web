class SampleGroupsController < ApplicationController
  before_action :load_vars_nested, only: [:create]
  before_action :check_create_permissions, only: [:create]

  def create
    @sample_group = SampleGroup.new(sample_group_params)
    @sample_group.organization = @organization
    @sample_group.created_by = current_user
    @sample_group.last_modified_by = current_user

    respond_to do |format|
      if @sample_group.save
        format.json {
          render json: {
            id: @sample_group.id,
            flash: t(
              'sample_groups.create.success_flash',
              sample_group: @sample_group.name,
              organization: @organization.name
            )
          },
          status: :ok
        }
      else
        format.json {
          render json: @sample_group.errors,
            status: :unprocessable_entity
        }
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
    unless can_create_sample_type_in_organization(@organization)
      render_403
    end
  end

  def sample_group_params
    params.require(:sample_group).permit(:name, :color)
  end
end
