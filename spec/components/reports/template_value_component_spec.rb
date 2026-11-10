# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::TemplateValueComponent, type: :component do
  let(:report) { create :report }
  let(:other_report) { create :report }

  def build(klass, name: 'field')
    klass.new(report: report, name: name, label: 'Label', placeholder: 'ph', editing: false)
  end

  it 'stores the constructor arguments' do
    component = build(Reports::TextInputComponent)
    expect(component.instance_variables.to_h { |v| [v, component.instance_variable_get(v)] })
      .to include(:@report => report, :@name => 'field', :@label => 'Label', :@placeholder => 'ph', :@editing => false)
  end

  it 'loads the stored value matching the component class name and field name' do
    report.report_template_values.create!(view_component: 'TextInputComponent', name: 'field', value: 'mine')
    expect(build(Reports::TextInputComponent).instance_variable_get(:@value)).to eq 'mine'
  end

  it 'ignores values of another view component, another name or another report' do
    report.report_template_values.create!(view_component: 'LargeTextInputComponent', name: 'field', value: 'x')
    report.report_template_values.create!(view_component: 'TextInputComponent', name: 'other', value: 'y')
    other_report.report_template_values.create!(view_component: 'TextInputComponent', name: 'field', value: 'z')
    expect(build(Reports::TextInputComponent).instance_variable_get(:@value)).to be_nil
  end
end
