# frozen_string_literal: true

class ResultCommentsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include ApplicationHelper
  include CommentHelper

  before_action :load_vars

  before_action :check_view_permissions, only: [:index]
  before_action :check_add_permissions, only: [:create]
  before_action :check_manage_permissions, only: %i(edit update destroy)

  def index
    comments = @result.last_comments(@last_comment_id, @per_page)
    more_url = result_result_comments_path(@result, format: :json, from: comments.first.id) unless comments.empty?
    comment_index_helper(comments, more_url)
  end

  def create
    @comment = ResultComment.new(
      message: comment_params[:message],
      user: current_user,
      result: @result
    )
    comment_create_helper(@comment)
  end

  def update
    old_text = @comment.message
    @comment.message = comment_params[:message]
    comment_update_helper(@comment, old_text)
  end

  def destroy
    comment_destroy_helper(@comment)
  end

  private

  def load_vars
    @last_comment_id = params[:from].to_i
    @per_page = Constants::COMMENTS_SEARCH_LIMIT
    @result = Result.find_by_id(params[:result_id])
    @my_module = @result.my_module

    render_404 unless @result
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
      old_text: old_text,
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
