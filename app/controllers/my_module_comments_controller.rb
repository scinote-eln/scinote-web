# frozen_string_literal: true

class MyModuleCommentsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include ApplicationHelper
  include CommentHelper

  before_action :load_vars
  before_action :check_view_permissions, only: :index
  before_action :check_add_permissions, only: [:create]
  before_action :check_manage_permissions, only: %i(edit update destroy)

  def index
    comments = @my_module.last_comments(@last_comment_id, @per_page)
    unless comments.empty?
      more_url = url_for(my_module_my_module_comments_url(@my_module, format: :json, from: comments.first.id))
    end
    comment_index_helper(comments, more_url, @last_comment_id.positive? ? nil : '/my_module_comments/index.html.erb')
  end

  def create
    @comment = TaskComment.new(
      message: comment_params[:message],
      user: current_user,
      my_module: @my_module
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
    @my_module = MyModule.find_by_id(params[:my_module_id])

    render_404 unless @my_module
  end

  def check_view_permissions
    render_403 unless can_read_experiment?(@my_module.experiment)
  end

  def check_add_permissions
    render_403 unless can_create_comments_in_module?(@my_module)
  end

  def check_manage_permissions
    @comment = TaskComment.find_by_id(params[:id])
    render_403 unless @comment.present? &&
                      can_manage_comment_in_module?(@comment.becomes(Comment))
  end

  def comment_params
    params.require(:comment).permit(:message)
  end

  def my_module_comment_annotation_notification(old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: @comment.message,
      title: t('notifications.my_module_comment_annotation_title',
               my_module: @my_module.name,
               user: current_user.full_name),
      message: t('notifications.my_module_annotation_message_html',
                 project: link_to(@my_module.experiment.project.name,
                                  project_url(@my_module
                                              .experiment
                                              .project)),
                 experiment: link_to(@my_module.experiment.name,
                                     canvas_experiment_url(@my_module
                                                           .experiment)),
                 my_module: link_to(@my_module.name,
                                    protocols_my_module_url(
                                      @my_module
                                    )))
    )
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: @my_module.experiment.project.team,
            project: @my_module.experiment.project,
            subject: @my_module,
            message_items: { my_module: @my_module.id })
  end
end
