class StepCommentsController < ApplicationController
  before_action :load_vars

  before_action :check_view_permissions, only: [ :index ]
  before_action :check_add_permissions, only: [ :new, :create ]

  def index
    @comments = @step.last_comments(@last_comment_id, @per_page)

    respond_to do |format|
      format.json {
        # 'index' partial includes header and form for adding new
        # messages. 'list' partial is used for showing more
        # comments.
        partial = "index.html.erb"
        partial = "list.html.erb" if @last_comment_id > 0
        more_url = ""
        if @comments.count > 0
          more_url = url_for(step_step_comments_path(@step,
                                                     format: :json,
                                                     from: @comments.last.id))
        end
        render :json => {
          per_page: @per_page,
          results_number: @comments.length,
          more_url: more_url,
          html: render_to_string({
            partial: partial,
            locals: {
              comments: @comments,
              more_comments_url: more_url
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
      if (@comment.valid? && @step.comments << @comment)

        # Generate activity (this can only occur in module,
        # but nonetheless check if my module is not nil)
        if @protocol.in_module?
          Activity.create(
            type_of: :add_comment_to_step,
            user: current_user,
            project: @step.my_module.experiment.project,
            my_module: @step.my_module,
            message: t(
              "activities.add_comment_to_step",
              user: current_user.full_name,
              step: @step.position + 1,
              step_name: @step.name
            )
          )
        end

        format.html {
          flash[:success] = t(
            "step_comments.create.success_flash",
            step: @step.name)
          redirect_to session.delete(:return_to)
        }
        format.json {
          render json: {
            html: render_to_string({
              partial: "comment.html.erb",
              locals: {
                comment: @comment
              }
            })
          },
          status: :created
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
    @step = Step.find_by_id(params[:step_id])
    @protocol = @step.protocol

    unless @step
      render_404
    end
  end

  def check_view_permissions
    unless can_view_step_comments(@protocol)
      render_403
    end
  end

  def check_add_permissions
    unless can_add_step_comment_in_protocol(@protocol)
      render_403
    end
  end

  def comment_params
    params.require(:comment).permit(:message)
  end

end
