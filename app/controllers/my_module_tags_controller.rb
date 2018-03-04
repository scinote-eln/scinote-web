class MyModuleTagsController < ApplicationController
  before_action :load_vars
  before_action :check_view_permissions, only: :index
  before_action :check_manage_permissions, only: %i(create index_edit destroy)

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

  def index
    respond_to do |format|
      format.json do
        render json: {
          html_canvas: render_to_string(
            partial: 'canvas/tags.html.erb',
            locals: { my_module: @my_module }
          ),
          html_module_header: render_to_string(
            partial: 'my_modules/tags.html.erb',
            locals: { my_module: @my_module }
          )
        }
      end
    end
  end

  def create
    @mt = MyModuleTag.new(mt_params.merge(my_module: @my_module))
    @mt.created_by = current_user
    @mt.save

    respond_to do |format|
      format.json do
        redirect_to my_module_tags_edit_path(format: :json), turbolinks: false,
                    status: 303
      end
    end
  end

  def destroy
    @mt = MyModuleTag.find_by_id(params[:id])
    @mt.destroy

    respond_to do |format|
      format.json do
        redirect_to my_module_tags_edit_path(format: :json), turbolinks: false,
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
    render_403 unless can_read_experiment?(@my_module.experiment)
  end

  def check_manage_permissions
    render_403 unless can_manage_tags?(@my_module.experiment.project)
  end

  def init_gui
    @tags = @my_module.unassigned_tags
  end

  def mt_params
    params.require(:my_module_tag).permit(:my_module_id, :tag_id)
  end
end
