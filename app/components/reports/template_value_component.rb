# frozen_string_literal: true

module Reports
  class TemplateValueComponent < ApplicationComponent
    def initialize(report:, name:, label:, placeholder: nil, editing: true)
      @report = report
      @name = name
      @label = label
      @placeholder = placeholder
      @editing = editing
      @value = @report.report_template_values.find_by(view_component: self.class.name.demodulize, name: name)&.value
    end
  end
end
