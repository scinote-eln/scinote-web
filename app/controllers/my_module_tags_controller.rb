class MyModuleTagsController < ApplicationController
  include InputSanitizeHelper

  before_action :load_vars, except: :canvas_index
  before_action :check_view_permissions, except: %i(canvas_index create destroy destroy_by_tag_id)
  before_action :check_manage_permissions, only: %i(create destroy destroy_by_tag_id)

  def index_edit
    @my_module_tags = @my_module.my_module_tags.order(:id)
    @unassigned_tags = @my_module.unassigned_tags.order(:id)
    @new_mmt = MyModuleTag.new(my_module: @my_module)
    @new_tag = Tag.new(project: @my_module.experiment.project)

    render json: {
      my_module: @my_module,
      html: render_to_string(partial: 'index_edit', formats: :html)
    }
  end

  def index
    render json: {
      html_module_header: render_to_string(
        partial: 'my_modules/tags',
        locals: { my_module: @my_module, editable: can_manage_my_module?(@my_module) },
        formats: :html
      )
    }
  end

  def assigned_tags
    render json: @my_module.my_module_tags, each_serializer: MyModuleTagSerializer
  end

  def canvas_index
    experiment = Experiment.find(params[:id])
    return render_403 unless can_read_experiment?(experiment)

    res = []
    experiment.my_modules.active.each do |my_module|
      res << {
        id: my_module.id,
        tags_html: render_to_string(
          partial: 'canvas/tags',
          locals: { my_module: my_module },
          formats: :html
        )
      }
    end

    render json: { my_modules: res }
  end

  def create
    return render_403 unless params[:my_module_tag] && mt_params[:tag_id]

    @mt = MyModuleTag.new(mt_params.merge(my_module: @my_module))
    @mt.created_by = current_user
    @mt.save

    my_module = @mt.my_module

    Activities::CreateActivityService
      .call(activity_type: :add_task_tag,
            owner: current_user,
            subject: my_module,
            project: my_module.project,
            team: my_module.team,
            message_items: {
              my_module: my_module.id,
              tag: @mt.tag.id
            })
    redirect_to my_module_tags_edit_path(format: :json), turbolinks: false,
                status: :see_other
  end

  def destroy
    @mt = MyModuleTag.find_by_id(params[:id])

    return render_404 unless @mt

    Activities::CreateActivityService
      .call(activity_type: :remove_task_tag,
            owner: current_user,
            subject: @mt.my_module,
            project: @mt.my_module.project,
            team: @mt.my_module.team,
            message_items: {
              my_module: @mt.my_module.id,
              tag: @mt.tag.id
            })

    @mt.destroy
    redirect_to my_module_tags_edit_path(format: :json), turbolinks: false,
                status: :see_other
  end

  def search_tags
    assigned_tags = @my_module.my_module_tags.select(:tag_id)
    all_tags = @my_module.experiment.project.tags
    tags = all_tags.where.not(id: assigned_tags)
                   .where_attributes_like(:name, params[:query])
                   .select(:id, :name, :color)
                   .limit(6)

    tags = tags.map do |tag|
      { value: tag.id, label: escape_input(tag.name), params: { color: escape_input(tag.color) } }
    end

    if params[:query].present? && tags.select { |tag| tag[:label] == params[:query] }.blank?
      tags << { value: 0, label: escape_input(params[:query]), params: { color: nil } }
    end

    render json: tags
  end

  def destroy_by_tag_id
    tag = @my_module.my_module_tags.find_by_tag_id(params[:id])

    Activities::CreateActivityService
      .call(activity_type: :remove_task_tag,
            owner: current_user,
            subject: tag.my_module,
            project: tag.my_module.project,
            team: tag.my_module.team,
            message_items: {
              my_module: tag.my_module.id,
              tag: tag.tag.id
            })

    return render_404 unless tag

    tag.destroy
    render json: { result: tag }
  end

  private

  def load_vars
    @my_module = MyModule.find_by_id(params[:my_module_id])

    render_404 if @my_module.blank?
  end

  def check_view_permissions
    render_403 unless can_read_my_module?(@my_module)
  end

  def check_manage_permissions
    render_403 unless can_manage_my_module_tags?(@my_module)
  end

  def mt_params
    params.require(:my_module_tag).permit(:my_module_id, :tag_id)
  end
end
