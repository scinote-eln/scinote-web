# frozen_string_literal: true

class ProjectCommentsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include ApplicationHelper
  include CommentHelper

  before_action :load_vars
  before_action :check_view_permissions, only: :index
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, only: %i(edit update destroy)

  def index
    comments = @project.last_comments(@last_comment_id, @per_page)
    more_url = project_project_comments_url(@project, format: :json, from: comments.first.id) unless comments.blank?
    comment_index_helper(comments, more_url, @last_comment_id.positive? ? nil : '/project_comments/index.html.erb')
  end

  def create
    @comment = ProjectComment.new(
      message: comment_params[:message],
      user: current_user,
      project: @project
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
    @project = Project.find_by_id(params[:project_id])

    render_404 unless @project
  end

  def check_view_permissions
    render_403 unless can_read_project?(@project)
  end

  def check_create_permissions
    render_403 unless can_create_comments_in_project?(@project)
  end

  def check_manage_permissions
    @comment = ProjectComment.find_by_id(params[:id])
    render_403 unless @comment.present? &&
                      can_manage_comment_in_project?(@comment)
  end

  def comment_params
    params.require(:comment).permit(:message)
  end
end
