# frozen_string_literal: true

module ProtocolReportTemplates
  class TagService
    def initialize(protocol)
      @protocol = protocol
    end

    def tags
      default_report_template_placeholders + step_tags + result_tags
    end

    def replace_tags(src_report_template, dest_report_template, src_object, include_results: true)
      original_blob = src_report_template.odt_template_file.blob
      output = Tempfile.new(['report', '.odt'])

      src_report_template.odt_template_file.open do |odt_template_file|
        report = ODFReport::Report.new(odt_template_file.path) do |r|
          src_object.steps.order(:position).zip(@protocol.steps.order(:position)) do |src_step, dest_step|
            r.add_field(build_tag('step', src_step.id, delimiter: false).to_sym, build_tag('step', dest_step.id))

            src_step.step_orderable_elements.order(:position).zip(dest_step.step_orderable_elements.order(:position)) do |src_element, dest_element|
              type = src_element.orderable_type.underscore
              if src_element.orderable_type == 'FormResponse'
                replace_form_response(r, src_element.orderable, dest_element.orderable)
              else
                r.add_field(build_tag(type, element_id(src_element), delimiter: false).to_sym, build_tag(type, element_id(dest_element)))
              end
            end
          end

          if include_results
            dest_object = @protocol.in_module? ? @protocol.my_module : @protocol
            src_object.results.order(:created_at).zip(dest_object.results.order(:created_at)) do |src_step, dest_step|
              r.add_field(build_tag('result', src_step.id, delimiter: false).to_sym, build_tag('result', dest_step.id))

              src_step.result_orderable_elements.order(:position).zip(dest_step.result_orderable_elements.order(:position)) do |src_element, dest_element|
                type = src_element.orderable_type.underscore
                r.add_field(build_tag(type, element_id(src_element), delimiter: false).to_sym, build_tag(type, element_id(dest_element)))
              end
            end
          end
        end
        report.generate(output.path)

        blob = ActiveStorage::Blob.create_and_upload!(
          io: File.open(output.path),
          filename: original_blob.filename,
          content_type: original_blob.content_type
        )
        dest_report_template.odt_template_file.attach(blob)
      end
    ensure
      output.close
      output.unlink
    end

    def replace_form_response_tags(report_template, src_form_response, dest_form_response)
      original_blob = report_template.odt_template_file.blob
      output = Tempfile.new(['report', '.odt'])

      report_template.odt_template_file.open do |odt_template_file|
        report = ODFReport::Report.new(odt_template_file.path) do |r|
          replace_form_response(r, src_form_response, dest_form_response)
        end
        report.generate(output.path)

        report_template.odt_template_file.attach(io: File.open(output.path), filename: original_blob.filename, content_type: original_blob.content_type)
      end
    ensure
      output.close
      output.unlink
    end

    private

    def step_tags
      @protocol.steps.ordered.map do |step|
        {
          label: step.name,
          tag: build_tag('step', step.id),
          inputs: tag_inputs(step.step_orderable_elements.order(:position))
        }
      end
    end

    def result_tags
      @protocol.results.map do |result|
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
              tag: I18n.t('protocols.report_template.data_inputs.codes.tag_form_field_code', form_id: element_id(element), id: form_field.id)
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

    def build_tag(type, id, delimiter: true)
      if delimiter
        I18n.t('protocols.report_template.data_inputs.codes.tag_content_code', content_type: I18n.t("protocols.report_template.data_inputs.codes.type.#{type}"), id: id)
      else
        I18n.t('protocols.report_template.data_inputs.codes.tag_content', content_type: I18n.t("protocols.report_template.data_inputs.codes.type.#{type}"), id: id)
      end
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

    def replace_form_response(report, src_form_response, dest_form_response)
      type = 'form_response'
      report.add_field(build_tag(type, src_form_response.id, delimiter: false).to_sym, build_tag(type, dest_form_response.id))

      src_form_response.form.form_fields.order(:position).zip(dest_form_response.form.form_fields.order(:position)) do |src_form_field, dest_form_field|
        report.add_field(I18n.t('protocols.report_template.data_inputs.codes.tag_form_field', form_id: src_form_response.id, id: src_form_field.id).to_sym,
                         I18n.t('protocols.report_template.data_inputs.codes.tag_form_field_code', form_id: dest_form_response.id, id: dest_form_field.id))
      end
    end

    def default_report_template_placeholders
      Extends::DEFAULT_REPORT_TEMPLATE_PLACEHOLDERS.map do |group|
        {
          label: group[:label],
          inputs: group[:inputs].map do |input|
            {
              label: I18n.t("protocols.report_template.data_inputs.codes.#{input}"),
              tag: I18n.t("protocols.report_template.data_inputs.codes.#{input}_code")
            }
          end
        }
      end
    end
  end
end
