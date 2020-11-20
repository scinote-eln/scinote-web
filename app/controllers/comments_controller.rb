# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :load_object, only: %i(index create)
  before_action :load_comment, only: %i(update delete)
  before_action :check_view_permissions, only: :index
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, only: %i(update delete)

  def index
    comments = @commentable.comments

    render json: {
      object_name: @commentable.name,
      comments: render_to_string(partial: 'shared/comments/comments_list.html.erb',
                                 locals: { comments: comments })
    }
  end

  def create; end

  def update; end

  def delete; end

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
    render_404 and return unless @commentable

    @commentable = @comment.commentable
    render_404 and return unless @commentable
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
    if @commentable.class == Project
      render_403 and return unless can_manage_comment_in_project?(@comment)
    elsif [MyModule, Step, Result].include? @commentable.class
      render_403 and return unless can_manage_comment_in_module?(@comment.becomes(Comment))
    else
      render_403 and return
    end
  end
end
