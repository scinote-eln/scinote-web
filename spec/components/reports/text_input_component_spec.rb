# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::TextInputComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:report) { create :report }

  def render_component(**opts)
    render_inline(described_class.new(report: report, name: 'title', label: 'Title', placeholder: 'Type here', **opts))
  end

  context 'when editing' do
    it 'renders an empty text field with label and placeholder' do
      page = render_component
      input = page.at_css('input[type=text][name=title]')
      expect(input['value']).to be_nil
      expect(input['placeholder']).to eq 'Type here'
      expect(input['data-type']).to eq 'TextInputComponent'
      expect(page.at_css('label[for=title]').text).to eq 'Title'
    end

    it 'prefills the stored value' do
      report.report_template_values.create!(view_component: 'TextInputComponent', name: 'title', value: 'My report')
      expect(render_component.at_css('input[name=title]')['value']).to eq 'My report'
    end
  end

  context 'when not editing' do
    it 'renders the stored value as plain text' do
      report.report_template_values.create!(view_component: 'TextInputComponent', name: 'title', value: 'My report')
      page = render_component(editing: false)
      expect(page.text.strip).to eq 'My report'
      expect(page.css('input')).to be_empty
    end
  end
end
