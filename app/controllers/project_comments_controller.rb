class ProjectCommentsController < ApplicationController
  before_action :load_vars
  before_action :check_view_permissions, only: [ :index ]
  before_action :check_add_permissions, only: [ :new, :create ]

  def index
    @comments = @project.last_comments(@last_comment_id, @per_page)

    respond_to do |format|
      format.json {
        # 'index' partial includes header and form for adding new
        # messages. 'list' partial is used for showing more
        # comments.
        partial = "index.html.erb"
        partial = "list.html.erb" if @last_comment_id > 0
        more_url = ""
        if @comments.count > 0
          more_url = url_for(project_project_comments_url(format: :json,
            from: @comments.last.id))
        end
        render :json => {
          :per_page => @per_page,
          :results_number => @comments.length,
          :more_url => more_url,
          :html => render_to_string({
            :partial => partial,
            :locals => {
              :comments => @comments,
              :more_comments_url => more_url
            }
          })
        }
      }
    end
  end

  def new
    @comment = Comment.new(
      user: current_user
    )
  end

  def create
    @comment = Comment.new(
      message: comment_params[:message],
      user: current_user)
    
    respond_to do |format|

      if (@comment.valid? && @project.comments << @comment)
        format.html {
          flash[:success] = t(
            "project_comments.create.success_flash",
            project: @project.name)
          redirect_to projects_path
        }
        format.json {
          render json: {
            html: render_to_string({
              partial: 'comment.html.erb',
              locals: {
                comment: @comment
              }
            })
          }, status: :created
        }
      else
        response.status = 400
        format.html { render :new }
        format.json {
          render json: {
            errors: @comment.errors.to_hash(true)
          } 
        }
      end
    end
  end

  private

  def load_vars
    @last_comment_id = params[:from].to_i
    @per_page = 10
    @project = Project.find_by_id(params[:project_id])

    unless @project
      render_404
    end
  end

  def check_view_permissions
    unless can_view_project_comments(@project)
      render_403
    end
  end

  def check_add_permissions
    unless can_add_comment_to_project(@project)
      render_403
    end
  end

  def comment_params
    params.require(:comment).permit(:message)
  end
end
