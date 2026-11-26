# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawMyModuleProtocol do
  include_context 'docx_report'

  let(:protocol) { my_module.protocol }

  def draw
    renderer.draw_my_module_protocol(my_module)
  end

  it 'draws the default protocol heading for an unnamed protocol' do
    protocol.update_columns(name: nil)
    draw
    expect(heading_texts(4)).to eq([I18n.t('projects.reports.elements.module.protocol.name')])
  end

  it 'draws the protocol name as heading' do
    protocol.update_columns(name: 'Western blot')
    draw
    expect(heading_texts(4)).to eq(['Western blot'])
  end

  it 'draws code, timestamp and description of a protocol with a description' do
    protocol.update_columns(description: '<p>Protocol <b>goal</b></p>')
    draw
    expect(all_text).to include(
      I18n.t('projects.reports.elements.module.protocol.user_time', code: protocol.original_code,
                                                                    timestamp: I18n.l(protocol.created_at, format: :full))
    )
    expect(all_text).to include('Protocol')
    expect(all_text).to include('goal')
  end

  it 'draws no description block without a description' do
    protocol.update_columns(description: nil)
    draw
    expect(all_text).not_to include(I18n.t('projects.reports.elements.module.protocol.user_time',
                                           code: protocol.original_code,
                                           timestamp: I18n.l(protocol.created_at, format: :full)))
  end

  context 'when timestamps are excluded' do
    let(:report_settings) { { exclude_timestamps: true } }

    it 'draws the description without the code line' do
      protocol.update_columns(description: '<p>Only text</p>')
      draw
      expect(all_text).to include('Only text')
      expect(all_text).not_to include(protocol.original_code.to_s + ' ')
    end
  end

  context 'when the protocol description setting is off' do
    let(:report_settings) { { task: { protocol: { description: false } } } }

    it 'does not draw the description' do
      protocol.update_columns(description: '<p>Hidden text</p>')
      draw
      expect(all_text).not_to include('Hidden text')
    end
  end
end
