# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::StepComments
  def draw_step_comments(comments, step)
    @docx.p
    @docx.p I18n.t 'projects.reports.elements.step_comments.name', step: step.name
    if comments.count.zero?
      @docx.p I18n.t 'projects.reports.elements.step_comments.no_comments'
    else
      @docx.ol do
        comments.each do |comment|
          comment_ts = comment.created_at
          li do
            text I18n.t('projects.reports.elements.step_comments.comment_prefix',
                        user: comment.user.full_name,
                        date: I18n.l(comment_ts, format: :full_date),
                        time: I18n.l(comment_ts, format: :time)), italic: true
            br
            text SmartAnnotations::TagToText.new(@user, @report_team, comment.message).text
            br
          end
        end
      end
    end
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
