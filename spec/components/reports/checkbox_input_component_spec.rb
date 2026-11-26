# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::CheckboxInputComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:report) { create :report }

  def add_value(value)
    report.report_template_values.create!(view_component: 'CheckboxInputComponent', name: 'agree', value: value)
  end

  def render_component(**opts)
    render_inline(described_class.new(report: report, name: 'agree', label: 'I agree', **opts))
  end

  context 'when editing' do
    it 'renders an unchecked checkbox with the label when there is no stored value' do
      page = render_component
      box = page.at_css('input[type=checkbox][name=agree]')
      expect(box).to be_present
      expect(box['data-type']).to eq 'CheckboxInputComponent'
      expect(box['checked']).to be_nil
      expect(page.text).to include('I agree')
    end

    it 'renders the checkbox checked when the stored value is true' do
      add_value(true)
      expect(render_component.at_css('input[name=agree]')['checked']).to be_present
    end
  end

  context 'when not editing' do
    it 'renders a selected marker for a true value' do
      add_value(true)
      expect(render_component(editing: false).css('.template-checkbox.selected').size).to eq 1
    end

    it 'renders an empty marker without the selected class when nothing is stored' do
      page = render_component(editing: false)
      expect(page.css('.template-checkbox').size).to eq 1
      expect(page.css('.template-checkbox.selected')).to be_empty
      expect(page.css('input')).to be_empty
    end
  end
end
