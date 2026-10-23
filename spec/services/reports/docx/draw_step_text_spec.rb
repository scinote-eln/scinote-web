# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawStepText do
  include_context 'docx_report'

  let(:step) { add_step(name: 'Text step') }
  let(:step_text) { create :step_text, step: step, name: 'Intro', text: '<p>Hello <strong>world</strong></p>' }

  def draw
    renderer.draw_step_text(step_text)
  end

  it 'draws the name, creation time and the html body' do
    draw
    texts = paragraph_texts
    expect(texts.first).to include('Intro')
    expect(texts.first).to include(
      I18n.t('projects.reports.elements.result_text.user_time', timestamp: I18n.l(step_text.created_at, format: :full))
    )
    expect(all_text).to include('Hello')
    expect(all_text).to include('world')
    expect(document_node.xpath('//r[rPr/b]').map { |r| r.text }).to include('world')
  end

  it 'draws a placeholder for an empty text' do
    step_text.update_columns(text: '')
    draw
    expect(all_text).to include(I18n.t('projects.reports.elements.step.no_description'))
  end

  it 'draws archive metadata for an archived text' do
    archived_on = Time.zone.local(2024, 7, 7, 7)
    step_text.update_columns(archived: true, archived_on: archived_on, archived_by_id: user.id)
    draw
    expect(all_text).to include(I18n.t('search.index.archived'))
    expect(all_text).to include(
      I18n.t('projects.reports.elements.archived_metadata', datetime: I18n.l(archived_on, format: :full),
                                                            user: user.full_name)
    )
  end

  context 'when timestamps are excluded' do
    let(:report_settings) { { exclude_timestamps: true } }

    it 'keeps the name without the timestamp' do
      draw
      expect(paragraph_texts.first).to eq('Intro ')
    end

    it 'draws no header paragraph for an unnamed text' do
      step_text.update_columns(name: nil)
      draw
      expect(all_text).not_to include(I18n.t('projects.reports.elements.result_text.user_time',
                                             timestamp: I18n.l(step_text.created_at, format: :full)))
      expect(all_text).to include('Hello')
    end
  end
end
