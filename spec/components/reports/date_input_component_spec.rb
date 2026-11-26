# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::DateInputComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:report) { create :report }
  let(:formatted) { I18n.l(Date.new(2024, 3, 5), format: :full) }

  def render_component(**opts)
    render_inline(described_class.new(report: report, name: 'when', label: 'When', placeholder: 'Pick', **opts))
  end

  def add_value
    report.report_template_values.create!(view_component: 'DateInputComponent', name: 'when', value: '2024-03-05')
  end

  context 'when editing' do
    it 'renders an empty picker input with the picker configuration' do
      page = render_component
      input = page.at_css('input[name=when]')
      expect(input['value']).to eq ''
      expect(input['placeholder']).to eq 'Pick'
      expect(input['data-toggle']).to eq 'date-time-picker'
      expect(input['data-type']).to eq 'DateInputComponent'
      expect(input['data-date-locale']).to eq I18n.locale.to_s
      expect(input['data-date-format']).to be_present
    end

    it 'shows the stored ISO date in the user date format' do
      add_value
      expect(render_component.at_css('input[name=when]')['value']).to eq formatted
    end
  end

  context 'when not editing' do
    it 'renders the localized date' do
      add_value
      expect(render_component(editing: false).text.strip).to eq formatted
    end

    it 'renders nothing when no value is stored' do
      expect(render_component(editing: false).text.strip).to eq ''
    end
  end
end
