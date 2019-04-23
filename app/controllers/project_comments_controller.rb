class ProjectCommentsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include ApplicationHelper
  include Rails.application.routes.url_helpers

  before_action :load_vars
  before_action :check_view_permissions, only: :index
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, only: %i(edit update destroy)

  def index
    @comments = @project.last_comments(@last_comment_id, @per_page)

    respond_to do |format|
      format.json do
        # 'index' partial includes header and form for adding new
        # messages. 'list' partial is used for showing more
        # comments.
        partial = 'index.html.erb'
        partial = 'list.html.erb' if @last_comment_id > 0
        more_url = ''
        if @comments.count > 0
          more_url = url_for(project_project_comments_url(format: :json,
                                                          from: @comments
                                                                  .first.id))
        end
        render json: {
          perPage: @per_page,
          resultsNumber: @comments.length,
          moreUrl: more_url,
          html: render_to_string(
            partial: partial,
            locals: {
              comments: @comments,
              more_comments_url: more_url
            }
          )
        }
      end
    end
  end

  def create
    @comment = ProjectComment.new(
      message: comment_params[:message],
      user: current_user,
      project: @project
    )

    respond_to do |format|
      if @comment.save
        project_comment_annotation_notification
        log_activity(:add_comment_to_project)

        format.json {
          render json: {
            html: render_to_string(
              partial: 'comment.html.erb',
              locals: {
                comment: @comment
              }
            ),
            date: I18n.l(@comment.created_at, format: :full_date),
            linked_id: @project.id,
            counter: @project.project_comments.count
          }, status: :created
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
      project_project_comment_path(@project, @comment, format: :json)
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
          project_comment_annotation_notification(old_text)
          log_activity(:edit_project_comment)

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
          log_activity(:delete_project_comment)

          # 'counter' and 'linked_id' are used for counter badge
          render json: { linked_id: @project.id,
                         counter: @project.project_comments.count },
                 status: :ok
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
    @project = Project.find_by_id(params[:project_id])

    unless @project
      render_404
    end
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

  def project_comment_annotation_notification(old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: @comment.message,
      title: t('notifications.project_comment_annotation_title',
               project: @project.name,
               user: current_user.full_name),
      message: t('notifications.project_annotation_message_html',
                 project: link_to(@project.name, project_url(@project)))
    )
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @project,
            team: @project.team,
            project: @project,
            message_items: { project: @project.id })
  end
end
