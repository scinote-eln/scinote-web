# frozen_string_literal: true

class MyModuleCommentsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include ApplicationHelper
  include CommentHelper

  before_action :load_vars
  before_action :load_comment, only: %i(update destroy)
  before_action :check_view_permissions, only: :index
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, only: %i(update destroy)

  def index
    comments = @my_module.last_comments(@last_comment_id, @per_page)
    unless comments.blank?
      more_url = url_for(my_module_my_module_comments_url(@my_module, format: :json, from: comments.first.id))
    end
    comment_index_helper(comments, more_url, @last_comment_id.positive? ? nil : '/my_module_comments/index')
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
    @my_module = MyModule.find_by(id: params[:my_module_id])

    render_404 unless @my_module
  end

  def load_comment
    @comment = @my_module.task_comments.find(params[:id])
  end

  def check_view_permissions
    render_403 unless can_read_my_module?(@my_module)
  end

  def check_create_permissions
    render_403 unless can_create_my_module_comments?(@my_module)
  end

  def check_manage_permissions
    render_403 unless can_manage_my_module_comment?(@comment)
  end

  def comment_params
    params.require(:comment).permit(:message)
  end
end
