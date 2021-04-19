# frozen_string_literal: true

module ReportActions
  class SaveReport
    def initialize(report, report_elements, template_values)
      @report = report
      @report_elements = report_elements
      @template_values = template_values
    end

    def save_with_contents
      Report.transaction do
        # Save the report itself
        @report.save!

        # Delete existing report elements
        @report.report_elements.destroy_all

        # Save new report elements
        @report_elements.each_with_index do |el, i|
          save_json_element(el, i, nil)
        end

        # Delete existing template values
        @report.report_template_values.destroy_all

        formatted_template_values = @template_values.as_json.map { |k, v| v['name'] = k; v }
        # Save new template values
        @report.report_template_values.create!(formatted_template_values)
      end

      @report
    rescue ActiveRecord::ActiveRecordError, ArgumentError => e
      Rails.logger.error e.message
      raise ActiveRecord::Rollback
    end

    private

    def save_json_element(report_element, index, parent)
      el = ReportElement.new
      el.position = index
      el.report = @report
      el.parent = parent
      el.type_of = report_element['type_of']
      el.sort_order = report_element['sort_order']
      el.set_element_references(report_element['id'])
      el.save!

      if report_element['children'].present?
        report_element['children'].each_with_index do |child, i|
          save_json_element(child, i, el)
        end
      end
    end
  end
end
