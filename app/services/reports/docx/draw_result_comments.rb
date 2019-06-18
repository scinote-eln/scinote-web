# frozen_string_literal: true

module DrawResultComments
  def draw_result_comments(subject)
    result = Result.find_by_id(subject['id']['result_id'])
    return unless result

    comments = result.result_comments.order(created_at: subject['sort_order'])
    return if comments.count.zero?

    @docx.p
    @docx.p I18n.t('projects.reports.elements.result_comments.name', result: result.name), bold: true
    team = @report_team
    user = @user
    @docx.ol do
      comments.each do |comment|
        comment_ts = comment.created_at
        li do
          text I18n.t('projects.reports.elements.result_comments.comment_prefix',
                      user: comment.user.full_name,
                      date: I18n.l(comment_ts, format: :full_date),
                      time: I18n.l(comment_ts, format: :time)), italic: true
          br
          text SmartAnnotations::TagToText.new(user, team, comment.message).text
          br
        end
      end
    end
  end
end
