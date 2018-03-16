class SampleGroupsController < ApplicationController
  before_action :load_vars_nested
  before_action :check_view_permissions, only: %i(index sample_group_element)
  before_action :check_manage_permissions, only: %i(create edit update destroy
                                                    destroy_confirmation)
  before_action :set_sample_group, except: %i(create index)
  before_action :set_project_my_module, only: :index
  layout 'fluid'

  def create
    @sample_group = SampleGroup.new(sample_group_params)
    @sample_group.team = @team
    @sample_group.created_by = current_user
    @sample_group.last_modified_by = current_user

    respond_to do |format|
      if @sample_group.save
        format.json do
          render json: {
            html: render_to_string(
              partial: 'sample_group.html.erb',
                       locals: { sample_group: @sample_group,
                                 team: @team }
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
    render_404 unless current_team
    @sample_groups = current_team.sample_groups
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
                                 team: @team }
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
                                 team: @team }
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
                               team: @team }
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
                               team: @team }
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
    redirect_back(fallback_location: root_path)
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
    @team = Team.find_by_id(params[:team_id])

    render_404 unless @team
  end

  def check_view_permissions
    render_403 unless can_read_team?(@team)
  end

  def check_manage_permissions
    render_403 unless can_manage_sample_types_and_groups?(@team)
  end

  def sample_group_params
    params.require(:sample_group).permit(:name, :color)
  end
end
