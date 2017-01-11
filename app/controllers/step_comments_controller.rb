class StepCommentsController < ApplicationController
  include ActionView::Helpers::TextHelper

  before_action :load_vars

  before_action :check_view_permissions, only: [:index]
  before_action :check_add_permissions, only: [:create]
  before_action :check_edit_permissions, only: [:edit, :update]
  before_action :check_destroy_permissions, only: [:destroy]

  def index
    @comments = @step.last_comments(@last_comment_id, @per_page)

    respond_to do |format|
      format.json do
        # 'index' partial includes header and form for adding new
        # messages. 'list' partial is used for showing more
        # comments.
        partial = 'index.html.erb'
        partial = 'list.html.erb' if @last_comment_id > 0
        more_url = ''
        if @comments.count > 0
          more_url = url_for(step_step_comments_path(@step,
                                                     format: :json,
                                                     from: @comments.first.id))
        end
        render json: {
          perPage: @per_page,
          resultsNumber: @comments.length,
          moreUrl: more_url,
          html: render_to_string(partial: partial,
                                 locals: { comments: @comments,
                                           more_comments_url: more_url })
        }
      end
    end
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

        format.json {
          render json: {
            html: render_to_string(
              partial: "comment.html.erb",
              locals: {
                comment: @comment
              }
            ),
            date: @comment.created_at.strftime('%d.%m.%Y')
          },
          status: :created
        }
      else
        response.status = 400
        format.json {
          render json: {
            errors: @comment.errors.to_hash(true)
          }
        }
      end
    end
  end

  def edit
    @update_url = step_step_comment_path(@step, @comment, format: :json)
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: '/comments/edit.html.erb'
          )
        }
      end
    end
  end

  def update
    @comment.message = comment_params[:message]
    respond_to do |format|
      format.json do
        if @comment.save
          # Generate activity
          if @protocol.in_module?
            Activity.create(
              type_of: :edit_step_comment,
              user: current_user,
              project: @step.my_module.experiment.project,
              my_module: @step.my_module,
              message: t(
                'activities.edit_step_comment',
                user: current_user.full_name,
                step: @step.position + 1,
                step_name: @step.name
              )
            )
          end
          render json: {
            comment: custom_auto_link(
              simple_format(@comment.message),
              link: :urls,
              html: { target: '_blank' }
            )
          }, status: :ok
        else
          render json: { errors: @comment.errors.to_hash(true) },
                 status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json do
        if @comment.destroy
          # Generate activity
          if @protocol.in_module?
            Activity.create(
              type_of: :delete_step_comment,
              user: current_user,
              project: @step.my_module.experiment.project,
              my_module: @step.my_module,
              message: t(
                'activities.delete_step_comment',
                user: current_user.full_name,
                step: @step.position + 1,
                step_name: @step.name
              )
            )
          end
          render json: {}, status: :ok
        else
          render json: { message: I18n.t('comments.delete_error') },
                 status: :unprocessable_entity
        end
      end
    end
  end

  private

  def load_vars
    @last_comment_id = params[:from].to_i
    @per_page = Constants::COMMENTS_SEARCH_LIMIT
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

  def check_edit_permissions
    @comment = Comment.find_by_id(params[:id])
    render_403 unless @comment.present? &&
                      can_edit_step_comment_in_protocol(@comment)
  end

  def check_destroy_permissions
    @comment = Comment.find_by_id(params[:id])
    render_403 unless @comment.present? &&
                      can_delete_step_comment_in_protocol(@comment)
  end

  def comment_params
    params.require(:comment).permit(:message)
  end
end
