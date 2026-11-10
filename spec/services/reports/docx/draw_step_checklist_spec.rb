# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawStepChecklist do
  include_context 'docx_report'

  let(:step) { add_step(name: 'List step') }
  let(:checklist) { create :checklist, step: step, name: 'Safety list' }

  before do
    create :checklist_item, checklist: checklist, text: 'wear gloves', checked: true, position: 0
    create :checklist_item, checklist: checklist, text: "line one\nline two", checked: false, position: 1
  end

  def draw
    renderer.draw_step_checklist(checklist)
  end

  it 'draws the checklist name with the creation time' do
    draw
    expect(all_text).to include(
      I18n.t('projects.reports.elements.step_checklist.checklist_name', name: 'Safety list')
    )
    expect(all_text).to include(
      I18n.t('projects.reports.elements.step_checklist.user_time',
             timestamp: I18n.l(checklist.created_at, format: :full))
    )
  end

  it 'draws one list item per checklist item and marks the checked ones' do
    draw
    items = document_node.xpath('//p[pPr/numPr]').map { |p| p.xpath('.//t').map(&:text).join }
    expect(items.size).to eq(2)
    expect(items.first).to eq(
      "wear gloves (#{I18n.t('projects.reports.elements.step_checklist.checked')})"
    )
    expect(items.last).to eq('line oneline two')
    expect(document_xml).to include('<w:br/>')
  end

  it 'draws archive metadata for an archived checklist' do
    archived_on = Time.zone.local(2024, 9, 9, 9)
    checklist.update_columns(archived: true, archived_on: archived_on, archived_by_id: user.id)
    draw
    expect(all_text).to include(I18n.t('search.index.archived'))
    expect(all_text).to include(
      I18n.t('projects.reports.elements.archived_metadata', datetime: I18n.l(archived_on, format: :full),
                                                            user: user.full_name)
    )
  end

  context 'when timestamps are excluded' do
    let(:report_settings) { { exclude_timestamps: true } }

    it 'draws no timestamp' do
      draw
      expect(all_text).not_to include(
        I18n.t('projects.reports.elements.step_checklist.user_time',
               timestamp: I18n.l(checklist.created_at, format: :full))
      )
    end
  end

  it 'draws no list for an empty checklist' do
    checklist.checklist_items.destroy_all
    draw
    expect(document_node.xpath('//p[pPr/numPr]')).to be_empty
    expect(all_text).to include('Safety list')
  end
end
