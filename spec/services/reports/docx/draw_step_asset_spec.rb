# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawStepAsset do
  include_context 'docx_report'

  let(:step) { add_step(name: 'File step') }
  let(:asset) { create(:step_asset, step: step, team: team).asset }

  def draw
    renderer.draw_step_asset(asset)
  end

  it 'draws the image preview, the file name, a download link and the timestamp' do
    stub_image_preview(asset)
    draw
    expect(document_node.xpath('//drawing').size).to eq(1)
    expect(all_text).to include(I18n.t('projects.reports.elements.step_asset.file_name', file: asset.file_name))
    expect(all_text).to include(I18n.t('projects.reports.elements.download'))
    expect(all_text).to include(
      I18n.t('projects.reports.elements.step_asset.user_time', timestamp: I18n.l(asset.created_at, format: :full))
    )
    expect(link_targets).to include(Rails.application.routes.url_helpers.asset_download_url(asset))
  end

  it 'draws a preview error line when the image cannot be rendered' do
    allow(Reports::Utils).to receive(:image_prepare).and_raise(StandardError, 'broken preview')
    draw
    expect(document_node.xpath('//drawing')).to be_empty
    expect(all_text).to include(I18n.t('projects.reports.index.generation.file_preview_generation_error'))
    expect(all_text).to include(asset.file_name)
  end

  it 'draws archive metadata for an archived file' do
    stub_image_preview(asset)
    archived_on = Time.zone.local(2024, 4, 4, 4)
    asset.update_columns(archived: true, archived_on: archived_on, archived_by_id: user.id)
    draw
    expect(all_text).to include(I18n.t('search.index.archived'))
    expect(all_text).to include(
      I18n.t('projects.reports.elements.archived_metadata', datetime: I18n.l(archived_on, format: :full),
                                                            user: user.full_name)
    )
  end

  context 'when timestamps are excluded' do
    let(:report_settings) { { exclude_timestamps: true } }

    it 'omits the timestamp' do
      stub_image_preview(asset)
      draw
      expect(all_text).not_to include(
        I18n.t('projects.reports.elements.step_asset.user_time', timestamp: I18n.l(asset.created_at, format: :full))
      )
    end
  end
end
