# frozen_string_literal: true

module CommentHelper
  def comment_action_url(comment)
    case comment.type
    when 'StepComment'
      step_step_comment_path(comment.step, comment, format: :json)
    when 'ResultComment'
      result_result_comment_path(comment.result, comment, format: :json)
    when 'ProjectComment'
      project_project_comment_path(comment.project, comment, format: :json)
    when 'TaskComment'
      my_module_my_module_comment_path(comment.my_module, comment, format: :json)
    end
  end

  def comment_index_helper(comments, more_url, partial = nil)
    partial ||= 'shared/comments/list.html.erb'
    render json: {
      perPage: @per_page,
      resultsNumber: comments.size,
      moreUrl: more_url,
      html: render_to_string(
        partial: partial, locals: { comments: comments }
      )
    }
  end

  def comment_create_helper(comment)
    if comment.save
      case comment.type
      when 'StepComment'
        step_comment_annotation_notification
        log_activity(:add_comment_to_step)
      when 'ResultComment'
        result_comment_annotation_notification
        log_activity(:add_comment_to_result)
      when 'ProjectComment'
        project_comment_annotation_notification
        log_activity(:add_comment_to_project)
      when 'TaskComment'
        my_module_comment_annotation_notification
        log_activity(:add_comment_to_module)
      end

      render json: {
        html: render_to_string(
          partial: '/shared/comments/item.html.erb',
          locals: {
            comment: comment
          }
        )
      }
    else
      render json: { errors: comment.errors.to_hash(true) }, status: :error
    end
  end

  def comment_editable?(comment)
    case comment.type
    when 'TaskComment', 'StepComment', 'ResultComment'
      can_manage_comment_in_module?(comment.becomes(Comment))
    when 'ProjectComment'
      can_manage_comment_in_project?(comment)
    else
      false
    end
  end

  def comment_update_helper(comment, old_text)
    if comment.save
      case comment.type
      when 'StepComment'
        step_comment_annotation_notification(old_text)
        log_activity(:edit_step_comment)
      when 'ResultComment'
        result_comment_annotation_notification(old_text)
        log_activity(:edit_result_comment)
      when 'ProjectComment'
        project_comment_annotation_notification(old_text)
        log_activity(:edit_project_comment)
      when 'TaskComment'
        my_module_comment_annotation_notification(old_text)
        log_activity(:edit_module_comment)
      end

      message = custom_auto_link(comment.message, team: current_team, simple_format: true)
      render json: { comment: message }, status: :ok
    else
      render json: { errors: comment.errors.to_hash(true) },
                 status: :unprocessable_entity
    end
  end

  def comment_destroy_helper(comment)
    if comment.destroy
      case comment.type
      when 'StepComment'
        log_activity(:delete_step_comment)
      when 'ResultComment'
        log_activity(:delete_result_comment)
      when 'ProjectComment'
        log_activity(:delete_project_comment)
      when 'TaskComment'
        log_activity(:delete_module_comment)
      end
      render json: {}, status: :ok
    else
      render json: { message: I18n.t('comments.delete_error') },
                 status: :unprocessable_entity
    end
  end
end
