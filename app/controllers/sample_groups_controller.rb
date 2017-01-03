class SampleGroupsController < ApplicationController
  before_action :load_vars_nested
  before_action :check_create_permissions
  before_action :set_sample_group, except: [:create, :index]
  before_action :set_project_my_module, only: :index
  layout 'fluid'

  def create
    @sample_group = SampleGroup.new(sample_group_params)
    @sample_group.organization = @organization
    @sample_group.created_by = current_user
    @sample_group.last_modified_by = current_user

    respond_to do |format|
      if @sample_group.save
        format.json do
          render json: {
            html: render_to_string(
              partial: 'sample_group.html.erb',
                       locals: { sample_group: @sample_group,
                                 organization: @organization }
            )
          },
          status: :ok
        end
      else
        format.json do
          render json: @sample_group.errors,
            status: :unprocessable_entity
        end
      end
    end
  end

  def index
    render_404 unless current_organization
    @sample_groups = current_organization.sample_groups
  end

  def update
    @sample_group.update_attributes(sample_group_params)

    respond_to do |format|
      format.json do
        if @sample_group.save
          render json: {
            html: render_to_string(
              partial: 'sample_group.html.erb',
                       locals: { sample_group: @sample_group,
                                 organization: @organization }
            )
          }
        else
          render json: @sample_group.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.json do
        render json: {
          html:
            render_to_string(
              partial: 'edit.html.erb',
                       locals: { sample_group: @sample_group,
                                 organization: @organization }
            ),
          id: @sample_group.id
        }
      end
    end
  end

  def sample_group_element
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'sample_group.html.erb',
                     locals: { sample_group: @sample_group,
                               organization: @organization }
          )
        }
      end
    end
  end

  def destroy_confirmation
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'delete_sample_group_modal.html.erb',
                     locals: { sample_group: @sample_group,
                               organization: @organization }
          )
        }
      end
    end
  end

  def destroy
    flash[:success] = t 'sample_groups.index.destroy_flash',
                        name: @sample_group.name
    Sample.where(sample_group: @sample_group).find_each do |sample|
      sample.update(sample_group_id: nil)
    end
    @sample_group.destroy
    redirect_to :back
  end

  private

  def set_project_my_module
    @project = Project.find_by_id(params[:project_id]) if params[:project_id]
    @experiment = Experiment
                  .find_by_id(params[:experiment_id]) if params[:experiment_id]
    @my_module = MyModule
                 .find_by_id(params[:my_module_id]) if params[:my_module_id]
    render_403 unless @project || @my_module
  end

  def set_sample_group
    @sample_group = SampleGroup.find_by_id(params[:id])
  end

  def load_vars_nested
    @organization = Organization.find_by_id(params[:organization_id])

    render_404 unless @organization
  end

  def check_create_permissions
    render_403 unless can_create_sample_type_in_organization(@organization)
  end

  def sample_group_params
    params.require(:sample_group).permit(:name, :color)
  end
end
