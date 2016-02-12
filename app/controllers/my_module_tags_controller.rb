class MyModuleTagsController < ApplicationController
  before_action :load_vars
  before_action :check_view_permissions, only: [:index_edit, :index]
  before_action :check_create_permissions, only: [:new, :create]
  before_action :check_destroy_permissions, only: [:destroy]

  def index_edit
    @my_module_tags = @my_module.my_module_tags
    @unassigned_tags = @my_module.unassigned_tags
    @new_mmt = MyModuleTag.new(my_module: @my_module)
    @new_tag = Tag.new(project: @my_module.project)

    respond_to do |format|
      format.json {
        render :json => {
          :my_module => @my_module,
          :html => render_to_string({
            :partial => "index_edit.html.erb"
          })
        }
      }
    end
  end

  def index
    respond_to do |format|
      format.json {
        render json: {
          html_canvas: render_to_string(
            partial: "canvas/tags.html.erb",
            locals: { my_module: @my_module }
          ),
          html_module_header: render_to_string(
            partial: "my_modules/tags.html.erb",
            locals: { my_module: @my_module }
          )
        }
      }
    end
  end

  def new
    session[:return_to] ||= request.referer
    @mt = MyModuleTag.new(my_module: @my_module)
    init_gui
  end

  def create
    @mt = MyModuleTag.new(mt_params.merge(my_module: @my_module))
    @mt.created_by = current_user

    if @mt.save
      flash_success = t(
        "my_module_tags.create.success_flash",
        tag: @mt.tag.name,
        module: @mt.my_module.name)

      respond_to do |format|
        format.html {
          flash[:success] = flash_success
          redirect_to session.delete(:return_to)
        }
        format.json {
          redirect_to my_module_tags_edit_path(format: :json), :status => 303
        }
      end
    else
      flash_error = t(
        "my_module_tags.create.error_flash",
        module: @mt.my_module.name)

      respond_to do |format|
        format.html {
          flash[:error] = flash_error
          init_gui
          render :new
        }
        format.json {
          # TODO
          redirect_to my_module_tags_edit_path(format: :json), :status => 303
        }
      end
    end
  end

  def destroy
    session[:return_to] ||= request.referer
    @mt = MyModuleTag.find_by_id(params[:id])

    if @mt.present? and @mt.destroy
      flash_success = t(
        "my_module_tags.destroy.success_flash",
        tag: @mt.tag.name,
        module: @mt.my_module.name)

      respond_to do |format|
        format.html {
          flash[:success] = flash_success
          redirect_to session.delete(:return_to)
        }
        format.json {
          redirect_to my_module_tags_edit_path(format: :json), :status => 303
        }
      end
    else
      flash_success = t(
        "my_module_tags.destroy.error_flash",
        tag: @mt.tag.name,
        module: @mt.my_module.name)

      respond_to do |format|
        format.html {
          flash[:error] = flash_error
          redirect_to session.delete(:return_to)
        }
        format.json {
          # TODO
          redirect_to my_module_tags_edit_path(format: :json), :status => 303
        }
      end
    end
  end

  private

  def load_vars
    @my_module = MyModule.find_by_id(params[:my_module_id])

    unless @my_module
      render_404
    end
  end

  def check_view_permissions
    unless can_edit_tags_for_module(@my_module)
      render_403
    end
  end

  def check_create_permissions
    unless can_add_tag_to_module(@my_module)
      render_403
    end
  end

  def check_destroy_permissions
    unless can_remove_tag_from_module(@my_module)
      render_403
    end
  end

  def init_gui
    @tags = @my_module.unassigned_tags
  end

  def mt_params
    params.require(:my_module_tag).permit(:my_module_id, :tag_id)
  end
end
