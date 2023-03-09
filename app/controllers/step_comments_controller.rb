# frozen_string_literal: true

class StepCommentsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include ApplicationHelper
  include CommentHelper

  before_action :load_vars

  before_action :check_view_permissions, only: [:index]
  before_action :check_add_permissions, only: [:create]
  before_action :check_update_permissions, only: %i(update)
  before_action :check_destroy_permissions, only: %i(destroy)

  def index
    comments = @step.last_comments(@last_comment_id, @per_page)
    more_url = step_step_comments_path(@step, format: :json, from: comments.first.id) unless comments.blank?
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
    render_403 unless can_create_my_module_comments?(@protocol.my_module)
  end

  def check_destroy_permissions
    @comment = @step.step_comments.find_by(id: params[:id])
    render_403 unless @comment.present? &&
                      can_delete_comment_in_my_module_steps?(@comment)
  end

  def check_update_permissions
    @comment = @step.step_comments.find_by(id: params[:id])
    render_403 unless @comment.present? &&
                      can_update_comment_in_my_module_steps?(@comment)
  end

  def comment_params
    params.require(:comment).permit(:message)
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @protocol,
            team: @step.my_module.team,
            project: @step.my_module.project,
            message_items: {
              my_module: @step.my_module.id,
              step: @step.id,
              step_position: { id: @step.id, value_for: 'position_plus_one' }
            })
  end
end
