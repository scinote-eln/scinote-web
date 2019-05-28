module CommentHelper

  def comment_action_url(comment)
    case comment.type
    when 'StepComment'
      return step_step_comment_path(comment.step, comment, format: :json)
    when 'ResultComment'
      return result_result_comment_path(comment.result, comment, format: :json)
    end
  end

  def comment_index_helper(comments, more_url)
    render  json: {
              perPage: @per_page,
              resultsNumber: comments.size,
              moreUrl: more_url,
              html: render_to_string(
                partial: 'shared/comments/list.html.erb', locals: { comments: comments}
              )
            }
  end

  def comment_create_helper(comment)
      if comment.save
        if comment.step
          step_comment_annotation_notification
          log_activity(:add_comment_to_step)
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
        render json: {errors: comment.errors.to_hash(true)}, status: :error
      end
  end

end