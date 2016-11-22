class MyModuleTagsController < ApplicationController
  before_action :load_vars
  before_action :check_view_permissions, only: [:index_edit]
  before_action :check_create_permissions, only: [:create]
  before_action :check_destroy_permissions, only: [:destroy]

  def index_edit
    @my_module_tags = @my_module.my_module_tags
    @unassigned_tags = @my_module.unassigned_tags
    @new_mmt = MyModuleTag.new(my_module: @my_module)
    @new_tag = Tag.new(project: @my_module.experiment.project)

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

  def create
    @mt = MyModuleTag.new(mt_params.merge(my_module: @my_module))
    @mt.created_by = current_user
    @mt.save

    respond_to do |format|
      format.json do
        redirect_to my_module_tags_edit_path(format: :json),
                    status: 303
      end
    end
  end

  def destroy
    @mt = MyModuleTag.find_by_id(params[:id])
    @mt.destroy

    respond_to do |format|
      format.json do
        redirect_to my_module_tags_edit_path(format: :json),
                    status: 303
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
