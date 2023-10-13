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
    comments = @commentable.comments.order(created_at: :asc)
    object_url = nil
    case @commentable
    when Step
      object_name = "#{@commentable.position + 1} #{@commentable.name}"
      object_url = link_to(t('comments.step_url'), "#stepContainer#{@commentable.id}", class: 'scroll-page-with-anchor')
    else
      object_name = @commentable.name
    end

    render json: {
      object_name: object_name,
      object_url: object_url,
      comment_addable: comment_addable?(@commentable),
      comments: render_to_string(partial: 'shared/comments/comments_list',
                                 locals: { comments: comments },
                                 formats: :html)
    }
  end

  def create
    @comment = @commentable.comments.new(
      message: params[:message],
      user: current_user,
      associated_id: @commentable.id
    )
    comment_create_helper(@comment, 'comment')
  end

  def update
    old_text = @comment.message
    @comment.message = params[:message]
    comment_update_helper(@comment, old_text, 'comment')
  end

  def destroy
    comment_destroy_helper(@comment)
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
      render_403 and return unless can_create_project_comments?(@commentable)
    when MyModule
      render_403 and return unless can_create_my_module_comments?(@commentable)
    when Step
      render_403 and return unless can_create_comments_in_my_module_steps?(@commentable.protocol.my_module)
    when Result
      render_403 and return unless can_create_my_module_result_comments?(@commentable.my_module)
    else
      render_403 and return
    end
  end

  def check_manage_permissions
    render_403 unless comment_editable?(@comment)
  end
end
