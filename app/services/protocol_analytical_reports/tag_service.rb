# frozen_string_literal: true

module ProtocolAnalyticalReports
  class TagService
    DEFAULT_INPUTS = [
      {
        label: 'General task data',
        inputs: [
          { label: I18n.t('protocols.analytical_reports.data_inputs.codes.task_name'), tag: I18n.t('protocols.analytical_reports.data_inputs.codes.task_name_code') },
          { label: I18n.t('protocols.analytical_reports.data_inputs.codes.task_due_date'), tag: I18n.t('protocols.analytical_reports.data_inputs.codes.task_due_date_code') },
          { label: I18n.t('protocols.analytical_reports.data_inputs.codes.task_tags'), tag: I18n.t('protocols.analytical_reports.data_inputs.codes.task_tags_code') },
          { label: I18n.t('protocols.analytical_reports.data_inputs.codes.task_protocol'), tag: I18n.t('protocols.analytical_reports.data_inputs.codes.task_protocol_code') }
        ]
      }
    ].freeze

    def initialize(protocol)
      @protocol = protocol
    end

    def call
      DEFAULT_INPUTS + step_tags + result_tags
    end

    private

    def step_tags
      @protocol.steps.includes(step_orderable_elements: :orderable).ordered.map do |step|
        {
          label: step.name,
          tag: build_tag('step', step.id),
          inputs: tag_inputs(step.step_orderable_elements.order(:position))
        }
      end
    end

    def result_tags
      @protocol.results.includes(result_orderable_elements: :orderable).map do |result|
        {
          label: result.name,
          tag: build_tag('result', result.id),
          inputs: tag_inputs(result.result_orderable_elements.order(:position))
        }
      end
    end

    def tag_inputs(elements)
      elements.map do |element|
        base_input = {
          label: element_label(element),
          tag: build_tag(element.orderable_type.underscore, element_id(element)),
          icon: icon(element.orderable_type)
        }

        if element.orderable_type == 'FormResponse'
          base_input = [base_input] + element.orderable.form.form_fields.order(:position).map do |form_field|
            {
              label: form_field.name,
              tag: I18n.t('protocols.analytical_reports.data_inputs.codes.tag_form_field_code', form_id: element.orderable.id, id: form_field.id)
            }
          end
        end

        base_input
      end.flatten
    end

    def element_id(element)
      case element.orderable_type
      when 'StepTable', 'ResultTable'
        element.orderable.table.id
      else
        element.orderable.id
      end
    end

    def element_label(element)
      case element.orderable_type
      when 'StepTable', 'ResultTable'
        element.orderable.table.name
      else
        element.orderable.name
      end
    end

    def build_tag(type, id)
      I18n.t('protocols.analytical_reports.data_inputs.codes.tag_content_code', content_type: I18n.t("protocols.analytical_reports.data_inputs.codes.type.#{type}"), id: id)
    end

    def icon(type)
      case type
      when 'StepText', 'ResultText'
        'sn-icon-result-text'
      when 'StepTable', 'ResultTable'
        'sn-icon-tables'
      when 'Checklist'
        'sn-icon-checkllist'
      else
        'sn-icon-forms'
      end
    end
  end
end
