# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::StepComments
  def draw_step_comments(comments, step)
    return false if comments.count.zero?

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
# rubocop:enable  Style/ClassAndModuleChildren
