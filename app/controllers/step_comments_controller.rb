# frozen_string_literal: true

class StepCommentsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include ApplicationHelper
  include CommentHelper

  before_action :load_vars

  before_action :check_view_permissions, only: [:index]
  before_action :check_add_permissions, only: [:create]
  before_action :check_manage_permissions, only: %i(edit update destroy)

  def index
    comments = @step.last_comments(@last_comment_id, @per_page)
    more_url = step_step_comments_path(@step, format: :json, from: comments.first.id) unless comments.empty?
    comment_index_helper(comments, more_url)
  end

  def create
    @comment = StepComment.new(
      message: comment_params[:message],
      user: current_user,
      step: @step
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
    @step = Step.find_by_id(params[:step_id])
    @protocol = @step&.protocol

    render_404 unless @step && @protocol
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
      old_text: old_text,
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
