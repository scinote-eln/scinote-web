class SampleTypesController < ApplicationController
  before_action :load_vars_nested
  before_action :check_view_permissions, only: %i(index sample_type_element)
  before_action :check_manage_permissions, only: %i(create edit update destroy
                                                    destroy_confirmation)
  before_action :set_sample_type, except: %i(create index)
  before_action :set_project_my_module, only: :index
  layout 'fluid'

  def create
    @sample_type = SampleType.new(sample_type_params)
    @sample_type.team = @team
    @sample_type.created_by = current_user
    @sample_type.last_modified_by = current_user

    respond_to do |format|
      if @sample_type.save
        format.json do
          render json: {
            html: render_to_string(
              partial: 'sample_type.html.erb',
                       locals: { sample_type: @sample_type,
                                 team: @team }
            )
          },
          status: :ok
        end
      else
        format.json do
          render json: @sample_type.errors,
            status: :unprocessable_entity
        end
      end
    end
  end

  def index
    render_404 unless current_team
    @sample_types = current_team.sample_types
  end

  def edit
    respond_to do |format|
      format.json do
        render json: {
          html:
            render_to_string(
              partial: 'edit.html.erb',
                       locals: { sample_type: @sample_type,
                                 team: @team }
            ),
          id: @sample_type.id
        }
      end
    end
  end

  def update
    @sample_type.update_attributes(sample_type_params)

    respond_to do |format|
      format.json do
        if @sample_type.save
          render json: {
            html: render_to_string(
              partial: 'sample_type.html.erb',
                       locals: { sample_type: @sample_type,
                                 team: @team }
            )
          }
        else
          render json: @sample_type.errors,
            status: :unprocessable_entity
        end
      end
    end
  end

  def destroy_confirmation
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'delete_sample_type_modal.html.erb',
                     locals: { sample_type: @sample_type,
                               team: @team }
          )
        }
      end
    end
  end

  def destroy
    flash[:success] = t 'sample_types.index.destroy_flash',
                        name: @sample_type.name
    Sample.where(sample_type: @sample_type).find_each do |sample|
      sample.update(sample_type_id: nil)
    end
    @sample_type.destroy
    redirect_back(fallback_location: root_path)
  end

  def sample_type_element
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'sample_type.html.erb',
                     locals: { sample_type: @sample_type,
                               team: @team }
          )
        }
      end
    end
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

  def set_sample_type
    @sample_type = SampleType.find_by_id(params[:id])
  end

  def sample_type_params
    params.require(:sample_type).permit(:name)
  end
end
