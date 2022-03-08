class ResultCommentsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include ApplicationHelper

  before_action :load_vars

  before_action :check_view_permissions, only: [:index]
  before_action :check_add_permissions, only: [:create]
  before_action :check_manage_permissions, only: %i(edit update destroy)

  def index
    @comments = @result.last_comments(@last_comment_id, @per_page)

    respond_to do |format|
      format.json do
        # 'index' partial includes header and form for adding new
        # messages. 'list' partial is used for showing more
        # comments.
        partial = 'index.html.erb'
        partial = 'list.html.erb' if @last_comment_id.positive?
        more_url = ''
        if @comments.size.positive?
          more_url = url_for(result_result_comments_path(@result,
                                                         format: :json,
                                                         from: @comments
                                                                 .first.id))
        end
        render json: {
          perPage: @per_page,
          resultsNumber: @comments.size,
          moreUrl: more_url,
          html: render_to_string(
            partial: partial,
            locals: {
              result: @result, comments: @comments, per_page: @per_page
            }
          )
        }
      end
    end
  end

  def create
    @comment = ResultComment.new(
      message: comment_params[:message],
      user: current_user,
      result: @result
    )

    respond_to do |format|
      if @comment.save
        result_comment_annotation_notification
        log_activity(:add_comment_to_result)

        format.json {
          render json: {
            html: render_to_string(
              partial: 'comment.html.erb',
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
    @update_url =
      result_result_comment_path(@result, @comment, format: :json)
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
          result_comment_annotation_notification(old_text)
          log_activity(:edit_result_comment)
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
          log_activity(:delete_result_comment)
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
    @result = Result.find_by_id(params[:result_id])
    @my_module = @result.my_module

    unless @result
      render_404
    end
  end

  def check_view_permissions
    render_403 unless can_read_experiment?(@my_module.experiment)
  end

  def check_add_permissions
    render_403 unless can_create_comments_in_module?(@my_module)
  end

  def check_manage_permissions
    @comment = ResultComment.find_by_id(params[:id])
    render_403 unless @comment.present? &&
                      can_manage_comment_in_module?(@comment.becomes(Comment))
  end

  def comment_params
    params.require(:comment).permit(:message)
  end

  def result_comment_annotation_notification(old_text = nil)
    smart_annotation_notification(
      old_text: (old_text if old_text),
      new_text: @comment.message,
      title: t('notifications.result_comment_annotation_title',
               result: @result.name,
               user: current_user.full_name),
      message: t('notifications.result_annotation_message_html',
                 project: link_to(@result.my_module.experiment.project.name,
                                  project_url(@result.my_module
                                                   .experiment
                                                   .project)),
                 experiment: link_to(@result.my_module.experiment.name,
                                     canvas_experiment_url(@result.my_module
                                                                  .experiment)),
                 my_module: link_to(@result.my_module.name,
                                    protocols_my_module_url(
                                      @result.my_module
                                    )))
    )
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @result,
            team: @result.my_module.experiment.project.team,
            project: @result.my_module.experiment.project,
            message_items: { result: @result.id })
  end
end
