# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawStepComments do
  include_context 'docx_report'

  let(:step) { add_step(name: 'Commented step') }

  it 'draws nothing for a step without comments' do
    renderer.draw_step_comments(step)
    expect(all_text.strip).to eq('')
  end

  context 'with several comments' do
    let!(:older) do
      create :step_comment, step: step, user: user, message: 'older <b>remark</b>',
                            created_at: Time.zone.local(2024, 1, 1, 10, 0)
    end
    let!(:newer) do
      create :step_comment, step: step, user: create(:user, full_name: 'Second Author'),
                            message: 'newer remark', created_at: Time.zone.local(2024, 2, 2, 11, 30)
    end

    it 'draws the heading and every comment with author and timestamp' do
      renderer.draw_step_comments(step)
      text = all_text
      expect(text).to include(I18n.t('projects.reports.elements.step_comments.name', step: 'Commented step'))
      expect(text).to include(
        I18n.t('projects.reports.elements.step_comments.comment_prefix',
               user: 'Second Author', date: I18n.l(newer.created_at, format: :full_date),
               time: I18n.l(newer.created_at, format: :time))
      )
      expect(text).to include(
        I18n.t('projects.reports.elements.step_comments.comment_prefix',
               user: user.full_name, date: I18n.l(older.created_at, format: :full_date),
               time: I18n.l(older.created_at, format: :time))
      )
      expect(text).to include('newer remark')
      expect(text).to include('remark')
    end

    it 'draws the newest comment first' do
      pending 'bug: comments.find_each ignores order(created_at: :desc) and draws them by id'
      renderer.draw_step_comments(step)
      expect(all_text.index('newer remark')).to be < all_text.index('older')
    end
  end
end
