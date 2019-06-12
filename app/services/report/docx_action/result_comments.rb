# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::ResultComments
  def draw_result_comments(result, order)
    comments = result.result_comments.order(created_at: order)
    return false if comments.count.zero?

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
# rubocop:enable  Style/ClassAndModuleChildren
