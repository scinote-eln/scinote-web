class TagsController < ApplicationController
  before_action :load_vars, only: [:create, :update, :destroy]
  before_action :load_vars_nested, only: [:update, :destroy]
  before_action :check_create_permissions, only: [:create]
  before_action :check_update_permissions, only: [:update]
  before_action :check_destroy_permissions, only: [:destroy]

  def create
    @tag = Tag.new(tag_params)
    @tag.created_by = current_user
    @tag.last_modified_by = current_user

    if @tag.name.blank?
      @tag.name = t("tags.create.new_name")
    end

    if @tag.color.blank?
      @tag.color = Constants::TAG_COLORS[0]
    end

    if @tag.save
      if params.include? "my_module_id"
        # Assign the tag to the specified module
        new_mmt = MyModuleTag.new(
          my_module_id: params[:my_module_id],
          tag_id: @tag.id)
        new_mmt.save
      end

      flash_success = t(
        "tags.create.success_flash",
        tag: @tag.name)
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
    if @tag.update_attributes(tag_params)
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

  # Currently unimplemented
  def check_create_permissions
    unless can_manage_tags?(@project)
      render_403
    end
  end

  def check_update_permissions
    unless can_manage_tags?(@project)
      render_403
    end
  end

  def check_destroy_permissions
    unless can_manage_tags?(@project)
      render_403
    end
  end

  def tag_params
    params.require(:tag).permit(:name, :color, :project_id)
  end
end
