class SampleGroupsController < ApplicationController
  before_action :load_vars, only: [:edit, :update]
  before_action :load_vars_nested, only: [:new, :create]
  before_action :check_create_permissions, only: [:new, :create]
  before_action :check_edit_permissions, only: [:edit, :update]

  def new
    @sample_group = SampleGroup.new
    session[:return_to] ||= request.referer
  end

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
              "sample_groups.create.success_flash",
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

  def edit

  end

  def update
    @sample_group.last_modified_by = current_user
    if @sample_group.update_attributes(sample_group_params)
      flash[:success] = t(
        "sample_groups.update.success_flash",
        sample_group: @sample_group.name,
        organization: @organization.name)
      redirect_to (session.delete(:return_to) || root_path)
    else
      render :edit
    end
  end

  def destroy
  end

  private

  def load_vars
    @sample_group = SampleGroup.find_by_id(params[:id])
    @organization = @sample_group.organization

    unless @sample_group
      render_404
    end
  end

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

  def check_edit_permissions
    unless can_edit_sample_type_in_organization(@organization)
      render_403
    end
  end

  def sample_group_params
    params.require(:sample_group).permit(:name, :color)
  end
end
