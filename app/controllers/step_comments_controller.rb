class StepCommentsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include ApplicationHelper
  include Rails.application.routes.url_helpers

  before_action :load_vars

  before_action :check_view_permissions, only: [:index]
  before_action :check_add_permissions, only: [:create]
  before_action :check_manage_permissions, only: %i(edit update destroy)

  def index
    @comments = @step.last_comments(@last_comment_id, @per_page)

    respond_to do |format|
      format.json do
        # 'index' partial includes header and form for adding new
        # messages. 'list' partial is used for showing more
        # comments.
        partial = 'index.html.erb'
        partial = 'list.html.erb' if @last_comment_id.positive?
        more_url = ''
        if @comments.size.positive?
          more_url = url_for(step_step_comments_path(@step,
                                                     format: :json,
                                                     from: @comments.first.id))
        end
        render json: {
          perPage: @per_page,
          resultsNumber: @comments.size,
          moreUrl: more_url,
          html: render_to_string(
            partial: partial,
            locals: { step: @step, comments: @comments, per_page: @per_page }
          )
        }
      end
    end
  end

  def create
    @comment = StepComment.new(
      message: comment_params[:message],
      user: current_user,
      step: @step
    )

    respond_to do |format|
      if @comment.save

        step_comment_annotation_notification
        # Generate activity (this can only occur in module,
        # but nonetheless check if my module is not nil)
        log_activity(:add_comment_to_step)

        format.json {
          render json: {
            html: render_to_string(
              partial: "comment.html.erb",
              locals: {
                comment: @comment
              }
            ),
            date: I18n.l(@comment.created_at, format: :full_date)
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
    old_text = @comment.message
    @comment.message = comment_params[:message]
    respond_to do |format|
      format.json do
        if @comment.save

          step_comment_annotation_notification(old_text)
          # Generate activity
          log_activity(:edit_step_comment)

          message = custom_auto_link(@comment.message, team: current_team)
          render json: { comment: message }, status: :ok
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
          log_activity(:delete_step_comment)
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
    render_403 unless can_read_protocol_in_module?(@protocol)
  end

  def check_add_permissions
    render_403 unless can_create_comments_in_module?(@protocol.my_module)
  end

  def check_manage_permissions
    @comment = StepComment.find_by_id(params[:id])
    render_403 unless @comment.present? &&
                      can_manage_comment_in_module?(@comment.becomes(Comment))
  end

  def comment_params
    params.require(:comment).permit(:message)
  end

  def step_comment_annotation_notification(old_text = nil)
    smart_annotation_notification(
      old_text: (old_text if old_text),
      new_text: comment_params[:message],
      title: t('notifications.step_comment_annotation_title',
               step: @step.name,
               user: current_user.full_name),
      message: t('notifications.step_annotation_message_html',
                 project: link_to(@step.my_module.experiment.project.name,
                                  project_url(@step.my_module
                                                   .experiment
                                                   .project)),
                 experiment: link_to(@step.my_module.experiment.name,
                                     canvas_experiment_url(@step.my_module
                                                                .experiment)),
                 my_module: link_to(@step.my_module.name,
                                    protocols_my_module_url(
                                      @step.my_module
                                    )),
                 step: link_to(@step.name,
                               protocols_my_module_url(@step.my_module)))
    )
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @protocol,
            team: current_team,
            project: @step.my_module.experiment.project,
            message_items: {
              my_module: @step.my_module.id,
              step: @step.id,
              step_position: { id: @step.id, value_for: 'position_plus_one' }
            })
  end
end
