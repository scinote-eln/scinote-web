class SampleTypesController < ApplicationController
  before_action :load_vars, only: [:edit, :update]
  before_action :load_vars_nested, only: [:new, :create]
  before_action :check_create_permissions, only: [:new, :create]
  before_action :check_edit_permissions, only: [:edit, :update]

  def new
    @sample_type = SampleType.new
    session[:return_to] ||= request.referer
  end

  def create
    @sample_type = SampleType.new(sample_type_params)
    @sample_type.organization = @organization
    @sample_type.created_by = current_user
    @sample_type.last_modified_by = current_user

    respond_to do |format|
      if @sample_type.save
        # flash[:success] = t(
        #   "sample_types.create.success_flash",
        #   sample_type: @sample_type.name,
        #   organization: @organization.name
        # )
        format.json {
          render json: {
            id: @sample_type.id,
            flash: t(
              "sample_types.create.success_flash",
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

  def edit

  end

  def update
    @sample_type.last_modified_by = current_user
    if @sample_type.update_attributes(sample_type_params)
      flash[:success] = t(
        "sample_types.update.success_flash",
        sample_type: @sample_type.name,
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
    @sample_type = SampleType.find_by_id(params[:id])
    @organization = @sample_type.organization

    unless @sample_type
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

  def sample_type_params
    params.require(:sample_type).permit(:name)
  end
end
