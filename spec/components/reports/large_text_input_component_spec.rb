# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::LargeTextInputComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:report) { create :report }

  def render_component(**opts)
    render_inline(described_class.new(report: report, name: 'notes', label: 'Notes', placeholder: 'Write', **opts))
  end

  context 'when editing' do
    it 'renders an empty textarea with label and placeholder' do
      page = render_component
      area = page.at_css('textarea[name=notes]')
      expect(area.text.strip).to eq ''
      expect(area['placeholder']).to eq 'Write'
      expect(area['data-type']).to eq 'LargeTextInputComponent'
      expect(page.at_css('label[for=notes]').text).to eq 'Notes'
    end

    it 'prefills the stored value' do
      report.report_template_values.create!(view_component: 'LargeTextInputComponent', name: 'notes', value: 'long text')
      expect(render_component.at_css('textarea[name=notes]').text).to include 'long text'
    end
  end

  context 'when not editing' do
    it 'renders the stored value without form controls' do
      report.report_template_values.create!(view_component: 'LargeTextInputComponent', name: 'notes', value: 'long text')
      page = render_component(editing: false)
      expect(page.text.strip).to eq 'long text'
      expect(page.css('textarea')).to be_empty
    end
  end
end
