# frozen_string_literal: true

module DrawStepComments
  def draw_step_comments(subject)
    step = Step.find_by_id(subject['id']['step_id'])
    return unless step

    comments = step.step_comments
    return if comments.count.zero?

    team = @report_team
    user = @user
    @docx.p
    @docx.p I18n.t('projects.reports.elements.step_comments.name', step: step.name), bold: true
    @docx.ol do
      comments.each do |comment|
        comment_ts = comment.created_at
        li do
          text I18n.t('projects.reports.elements.step_comments.comment_prefix',
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
