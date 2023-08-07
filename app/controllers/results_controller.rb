# frozen_string_literal: true

class ResultsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i(create destroy)

  before_action :load_my_module
  before_action :load_vars, only: %i(destroy elements assets)
  before_action :check_destroy_permissions, only: :destroy

  def index
    respond_to do |format|
      format.json do
        # API endpoint
        render(
          json: apply_sort(@my_module.results),
          formats: :json
        )
      end

      format.html do
        # Main view
        @experiment = @my_module.experiment
        @project = @experiment.project
        render(:index, formats: :html)
      end
    end
  end

  def create
    result = @my_module.results.create!(user: current_user)

    render json: result
  end

  def elements
    render json: @result.result_orderable_elements.order(:position),
           each_serializer: ResultOrderableElementSerializer,
           user: current_user
  end

  def assets
    render json: @result.assets,
           each_serializer: AssetSerializer,
           user: current_user
  end

  def destroy
    result_type = if @result.is_text
                    t('activities.result_type.text')
                  elsif @result.is_table
                    t('activities.result_type.table')
                  elsif @result.is_asset
                    t('activities.result_type.asset')
                  end
    Activities::CreateActivityService
      .call(activity_type: :destroy_result,
            owner: current_user,
            subject: @result,
            team: @my_module.team,
            project: @my_module.project,
            message_items: { result: @result.id,
                             type_of_result: result_type })
    flash[:success] = t('my_modules.module_archive.delete_flash',
                        result: @result.name,
                        module: @my_module.name)
    @result.destroy
    redirect_to archive_my_module_path(@my_module)
  end

  private

  def apply_sort(results)
    case params[:sort]
    when 'updated_at_asc'
      results.order(updated_at: :asc)
    when 'updated_at_desc'
      results.order(updated_at: :desc)
    when 'created_at_asc'
      results.order(created_at: :asc)
    when 'created_at_desc'
      results.order(created_at: :desc)
    when 'name_asc'
      results.order(name: :asc)
    when 'name_desc'
      results.order(name: :desc)
    end
  end

  def load_my_module
    @my_module = MyModule.readable_by_user(current_user).find(params[:my_module_id])
  end

  def load_vars
    @result = @my_module.results.find(params[:id])

    return render_403 unless @result

    @my_module = @result.my_module
  end

  def check_destroy_permissions
    render_403 unless can_delete_result?(@result)
  end
end
