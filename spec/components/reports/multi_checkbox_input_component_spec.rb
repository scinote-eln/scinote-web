# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::MultiCheckboxInputComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:report) { create :report }
  let(:items) { { 1 => 'First', 2 => 'Second' } }

  def render_component(**opts)
    render_inline(described_class.new(report: report, name: 'opts', label: 'Options', items: items, **opts))
  end

  def add_value(value)
    report.report_template_values.create!(view_component: 'MultiCheckboxInputComponent', name: 'opts', value: value)
  end

  context 'when editing' do
    it 'renders one unchecked checkbox per item when nothing is stored' do
      boxes = render_component.css('input[type=checkbox][name="opts[]"]')
      expect(boxes.map { |b| b['value'] }).to eq %w(1 2)
      expect(boxes.map { |b| b['checked'] }).to all(be_nil)
    end

    it 'checks the boxes whose keys are truthy in the stored value' do
      add_value('1' => true)
      boxes = render_component.css('input[name="opts[]"]')
      expect(boxes.to_h { |b| [b['value'], b['checked'].present?] }).to eq('1' => true, '2' => false)
    end

    it 'shows the item labels' do
      expect(render_component.css('li').map { |li| li.text.strip }).to eq %w(First Second)
    end
  end

  context 'when not editing' do
    it 'marks only the selected items' do
      add_value('2' => true)
      page = render_component(editing: false)
      expect(page.css('li').map { |li| [li.text.strip, li.at_css('.template-checkbox').classes.include?('selected')] })
        .to eq [['First', false], ['Second', true]]
      expect(page.css('input')).to be_empty
    end

    it 'renders no selection when nothing is stored' do
      expect(render_component(editing: false).css('.selected')).to be_empty
    end
  end

  it 'defaults to no items' do
    page = render_inline(described_class.new(report: report, name: 'opts', label: 'Options'))
    expect(page.css('li')).to be_empty
  end
end
