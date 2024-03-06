class TagsController < ApplicationController
  before_action :load_vars, only: %i(index create update destroy)
  before_action :load_vars_nested, only: [:update, :destroy]
  before_action :check_manage_permissions, only: %i(create update destroy)

  def index
    render json: @project.tags, each_serializer: TagSerializer
  end

  def create
    @tag = Tag.new(tag_params)
    @tag.created_by = current_user
    @tag.last_modified_by = current_user
    @tag.project ||= @project

    if @tag.name.blank?
      @tag.name = t("tags.create.new_name")
    end

    if @tag.color.blank?
      @tag.color = Constants::TAG_COLORS.sample
    end

    if @tag.save
      log_activity(:create_tag, @tag.project, tag: @tag.id, project: @tag.project.id)
      if params.include? "my_module_id"
        # Assign the tag to the specified module
        new_mmt = MyModuleTag.new(
          my_module_id: params[:my_module_id],
          tag_id: @tag.id)
        new_mmt.save

        my_module = new_mmt.my_module

        log_activity(:add_task_tag, my_module, tag: @tag.id, my_module: my_module.id)
      end

      flash_success = t(
        "tags.create.success_flash",
        tag: @tag.name)

      if params[:simple_creation] == 'true'
        render json: {tag: @tag}
        return true
      end

      respond_to do |format|
        format.html {
          flash[:success] = flash_success
          redirect_to session.delete(:return_to)
        }
        format.json do
          redirect_to my_module_tags_edit_path(params[:my_module_id],
                                               @tag,
                                               format: :json),
                      turbolinks: false,
                      status: 303
        end
      end
    else
      flash_error = t("tags.create.error_flash")
      respond_to do |format|
        format.html {
          flash[:error] = flash_error
          render :new
        }
        format.json do
          # TODO
          redirect_to my_module_tags_edit_path(params[:my_module_id],
                                               @tag,
                                               format: :json),
                      turbolinks: false,
                      status: 303
        end
      end
    end
  end

  def update
    @tag.last_modified_by = current_user
    if @tag.update(tag_params)
      log_activity(:edit_tag, @tag.project, tag: @tag.id, project: @tag.project.id)
      respond_to do |format|
        format.html
        format.json do
          redirect_to my_module_tags_edit_path(params[:my_module_id],
                                               @tag,
                                               format: :json),
                      turbolinks: false,
                      status: 303
        end
      end
    else
      respond_to do |format|
        format.html
        format.json {
          render json: @tag.errors, status: :unprocessable_entity
        }
      end
    end
  end

  def destroy
    log_activity(:delete_tag, @tag.project, tag: @tag.id, project: @tag.project.id)
    if @tag.destroy
      flash_success = t(
        "tags.destroy.success_flash",
        tag: @tag.name)

      respond_to do |format|
        format.html {
          flash[:success] = flash_success
          redirect_to root_path
        }
        format.json do
          redirect_to my_module_tags_edit_path(params[:my_module_id],
                                               @tag,
                                               format: :json),
                      turbolinks: false,
                      status: 303
        end
      end
    else
      flash_error = t(
        "tags.destroy.error_flash",
        tag: @tag.name)

      respond_to do |format|
        format.html {
          flash[:error] = flash_error
          redirect_to root_path
        }
        format.json do
          # TODO
          redirect_to my_module_tags_edit_path(format: :json),
                      turbolinks: false,
                      status: 303
        end
      end
    end
  end

  private

  def load_vars
    @project = Project.find_by_id(params[:project_id])

    unless @project
      render_404
    end
  end

  def load_vars_nested
    @tag = Tag.find_by_id(params[:id])

    unless @tag
      render_404
    end
  end

  def check_manage_permissions
    my_module = MyModule.find_by id: params[:my_module_id]

    render_403 if my_module && !can_manage_my_module_tags?(my_module)
  end

  def tag_params
    params.require(:tag).permit(:name, :color, :project_id)
  end

  def log_activity(type_of, subject = nil, message_items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: subject,
            team: @tag.project.team,
            project: @tag.project,
            message_items: message_items)
  end
end
