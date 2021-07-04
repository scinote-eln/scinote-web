# frozen_string_literal: true

module Reports
  class MultiCheckboxInputComponent < TemplateValueComponent
    def initialize(report:, name:, label:, placeholder: nil, editing: true, items: {})
      super(report: report, name: name, label: label, placeholder: placeholder, editing: editing)
      @items = items
    end
  end
end
