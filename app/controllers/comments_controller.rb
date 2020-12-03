# frozen_string_literal: true

class CommentsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include ApplicationHelper
  include CommentHelper

  before_action :load_object, only: %i(index create)
  before_action :load_comment, only: %i(update destroy)
  before_action :check_view_permissions, only: :index
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, only: %i(update destroy)

  def index
    comments = @commentable.comments

    render json: {
      object_name: @commentable.name,
      comments: render_to_string(partial: 'shared/comments/comments_list.html.erb',
                                 locals: { comments: comments })
    }
  end

  def create
    @comment = @commentable.comments.new(
      message: params[:message],
      user: current_user,
      associated_id: @commentable.id
    )
    comment_create_helper(@comment, 'comment', @commentable.comments.size)
  end

  def update
    old_text = @comment.message
    @comment.message = params[:message]
    comment_update_helper(@comment, old_text, 'comment')
  end

  def destroy
    comment_destroy_helper(@comment, @commentable.comments.size - 1)
  end

  private

  def load_object
    @commentable = case params[:object_type]
                   when 'Project'
                     Project.find_by(id: params[:object_id])
                   when 'MyModule'
                     MyModule.find_by(id: params[:object_id])
                   when 'Step'
                     Step.find_by(id: params[:object_id])
                   when 'Result'
                     Result.find_by(id: params[:object_id])
                   end

    render_404 and return unless @commentable
  end

  def load_comment
    @comment = Comment.find_by(id: params[:id])
    render_404 and return unless @comment

    @commentable = @comment.commentable
    render_404 and return unless @commentable
  end

  def comment_params
    params.permit(:message)
  end

  def check_view_permissions
    case @commentable
    when Project
      render_403 and return unless can_read_project?(@commentable)
    when MyModule
      render_403 and return unless can_read_experiment?(@commentable.experiment)
    when Step
      render_403 and return unless can_read_protocol_in_module?(@commentable.protocol)
    when Result
      render_403 and return unless can_read_experiment?(@commentable.my_module.experiment)
    else
      render_403 and return
    end
  end

  def check_create_permissions
    case @commentable
    when Project
      render_403 and return unless can_create_comments_in_project?(@commentable)
    when MyModule
      render_403 and return unless can_create_comments_in_module?(@commentable)
    when Step
      render_403 and return unless can_create_comments_in_module?(@commentable.protocol.my_module)
    when Result
      render_403 and return unless can_create_comments_in_module?(@commentable.my_module)
    else
      render_403 and return
    end
  end

  def check_manage_permissions
    comment_editable?(@comment)
  end
end
