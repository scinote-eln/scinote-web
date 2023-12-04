# frozen_string_literal: true

module CommentHelper
  def comment_create_helper(comment, partial = 'item')
    if comment.save
      case comment.type
      when 'StepComment'
        step_comment_annotation_notification(comment)
        log_step_activity(:add_comment_to_step, comment)
      when 'ResultComment'
        result_comment_annotation_notification(comment)
        log_result_activity(:add_comment_to_result, comment)
      when 'ProjectComment'
        project_comment_annotation_notification(comment)
        log_project_activity(:add_comment_to_project, comment)
      when 'TaskComment'
        my_module_comment_annotation_notification(comment)
        log_my_module_activity(:add_comment_to_module, comment)
      end

      render json: {
        html: render_to_string(
          partial: "shared/comments/#{partial}",
          locals: {
            comment: comment,
            skip_header: false
          },
          formats: :html
        )
      }
    else
      render json: { errors: comment.errors.to_hash(true) }, status: :unprocessable_entity
    end
  end

  def comment_addable?(object)
    case object.class.name
    when 'MyModule'
      can_create_my_module_comments?(object)
    when 'Step'
      can_create_comments_in_my_module_steps?(object.my_module)
    when 'Result'
      can_create_my_module_result_comments?(object.my_module) && object.active?
    when 'Project'
      can_create_project_comments?(object)
    else
      false
    end
  end

  def comment_editable?(comment)
    case comment.type
    when 'TaskComment'
      can_manage_my_module_comment?(comment)
    when 'StepComment'
      can_update_comment_in_my_module_steps?(comment)
    when 'ResultComment'
      can_manage_result_comment?(comment)
    when 'ProjectComment'
      can_manage_project_comment?(comment)
    else
      false
    end
  end

  def comment_update_helper(comment, old_text, partial = nil)
    if comment.save
      case comment.type
      when 'StepComment'
        step_comment_annotation_notification(comment, old_text)
        log_step_activity(:edit_step_comment, comment)
      when 'ResultComment'
        result_comment_annotation_notification(comment, old_text)
        log_result_activity(:edit_result_comment, comment)
      when 'ProjectComment'
        project_comment_annotation_notification(comment, old_text)
        log_project_activity(:edit_project_comment, comment)
      when 'TaskComment'
        my_module_comment_annotation_notification(comment, old_text)
        log_my_module_activity(:edit_module_comment, comment)
      end

      if partial
        render json: {
          html: render_to_string(
            partial: "/shared/comments/#{partial}",
            locals: {
              comment: comment,
              skip_header: false
            },
            formats: :html
          )
        }
      else
        message = custom_auto_link(comment.message, team: current_team, simple_format: true)
        render json: { comment: message }, status: :ok
      end
    else
      render json: { errors: comment.errors.to_hash(true) },
                 status: :unprocessable_entity
    end
  end

  def comment_destroy_helper(comment)
    if comment.destroy
      case comment.type
      when 'StepComment'
        log_step_activity(:delete_step_comment, comment)
      when 'ResultComment'
        log_result_activity(:delete_result_comment, comment)
      when 'ProjectComment'
        log_project_activity(:delete_project_comment, comment)
      when 'TaskComment'
        log_my_module_activity(:delete_module_comment, comment)
      end
      render json: {}, status: :ok
    else
      render json: { message: I18n.t('comments.delete_error') },
                 status: :unprocessable_entity
    end
  end

  def result_comment_annotation_notification(comment, old_text = nil)
    result = comment.result
    smart_annotation_notification(
      old_text: old_text,
      new_text: comment.message,
      subject: result,
      title: t('notifications.result_comment_annotation_title',
               result: result.name,
               user: current_user.full_name),
      message: t('notifications.result_annotation_message_html',
                 project: link_to(result.my_module.experiment.project.name,
                                  project_url(result.my_module
                                                   .experiment
                                                   .project)),
                 experiment: link_to(result.my_module.experiment.name,
                                     my_modules_experiment_url(result.my_module.experiment)),
                 my_module: link_to(result.my_module.name,
                                    protocols_my_module_url(
                                      result.my_module
                                    )))
    )
  end

  def project_comment_annotation_notification(comment, old_text = nil)
    project = comment.project
    smart_annotation_notification(
      old_text: old_text,
      new_text: comment.message,
      subject: project,
      title: t('notifications.project_comment_annotation_title',
               project: project.name,
               user: current_user.full_name),
      message: t('notifications.project_annotation_message_html',
                 project: link_to(project.name, project_url(project)))
    )
  end

  def step_comment_annotation_notification(comment, old_text = nil)
    step = comment.step
    smart_annotation_notification(
      old_text: old_text,
      new_text: comment.message,
      subject: step.protocol,
      title: t('notifications.step_comment_annotation_title',
               step: step.name,
               user: current_user.full_name),
      message: t('notifications.step_annotation_message_html',
                 project: link_to(step.my_module.experiment.project.name,
                                  project_url(step.my_module
                                                   .experiment
                                                   .project)),
                 experiment: link_to(step.my_module.experiment.name,
                                     my_modules_experiment_url(step.my_module.experiment)),
                 my_module: link_to(step.my_module.name,
                                    protocols_my_module_url(
                                      step.my_module
                                    )),
                 step: link_to(step.name,
                               protocols_my_module_url(step.my_module)))
    )
  end

  def my_module_comment_annotation_notification(comment, old_text = nil)
    my_module = comment.my_module
    smart_annotation_notification(
      old_text: old_text,
      new_text: comment.message,
      subject: my_module,
      title: t('notifications.my_module_comment_annotation_title',
               my_module: my_module.name,
               user: current_user.full_name),
      message: t('notifications.my_module_comment_annotation_message_html',
                 project: link_to(my_module.experiment.project.name,
                                  project_url(my_module
                                              .experiment
                                              .project)),
                 experiment: link_to(my_module.experiment.name,
                                     my_modules_experiment_url(my_module.experiment)),
                 my_module: link_to(my_module.name,
                                    protocols_my_module_url(
                                      my_module
                                    )))
    )
  end

  def log_my_module_activity(type_of, comment)
    my_module = comment.my_module
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: my_module.experiment.project.team,
            project: my_module.experiment.project,
            subject: my_module,
            message_items: { my_module: my_module.id })
  end

  def log_project_activity(type_of, comment)
    project = comment.project
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: project,
            team: project.team,
            project: project,
            message_items: { project: project.id })
  end

  def log_step_activity(type_of, comment)
    step = comment.step
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: step.protocol,
            team: step.my_module.experiment.project.team,
            project: step.my_module.experiment.project,
            message_items: {
              my_module: step.my_module.id,
              step: step.id,
              step_position: { id: step.id, value_for: 'position_plus_one' }
            })
  end

  def log_result_activity(type_of, comment)
    result = comment.result
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: result,
            team: result.my_module.experiment.project.team,
            project: result.my_module.experiment.project,
            message_items: { result: result.id })
  end

  def has_unseen_comments?(commentable)
    commentable.comments.any? { |comment| comment.unseen_by.include?(current_user.id) }
  end

  def count_unseen_comments(commentable, current_user)
    commentable.comments.count { |comment| comment.unseen_by.include?(current_user.id) }
  end
end
