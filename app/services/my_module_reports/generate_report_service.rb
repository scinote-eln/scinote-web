# frozen_string_literal: true

module MyModuleReports
  class GenerateReportService
    include FormFieldValuesHelper

    PROTOCOL_TAG = :PROTOCOL
    CHECKED_SYMBOL = "\u22A0"

    def initialize(protocol, report_template, team, user)
      @report_template = report_template
      @my_module = protocol.my_module
      @team = team
      @user = user
      @tiny_mce_assets = []
    end

    def call(analytical_report)
      original_blob = @report_template.odt_template_file.blob
      output = Tempfile.new(['report', '.odt'])

      @report_template.odt_template_file.open do |odt_template_file|
        report = ODFReport::Report.new(odt_template_file.path) do |r|
          render_general(r)
          render_steps(r)
          render_results(r)
        end

        # Finally insert all TinyMCE images into the report
        @tiny_mce_assets.each do |tiny_mce_asset|
          report.add_inline_image :"TINY_MCE_ASSET_#{tiny_mce_asset[:id]}", tiny_mce_asset[:file].path, width: tiny_mce_asset[:width], height: tiny_mce_asset[:height]
        end

        report.generate(output.path)
        analytical_report.report.attach(io: File.open(output.path), filename: original_blob.filename, content_type: original_blob.content_type)
      end
    ensure
      @tiny_mce_assets.each { |tiny_mce_asset| tiny_mce_asset[:file]&.close! }
      output.close!
    end

    private

    def render_general(report)
      report.add_field :TASKNAME, @my_module.name
      report.add_field :TASKDUEDATE, @my_module.due_date ? I18n.l(@my_module.due_date, format: :full) : ''
      report.add_text :TASKTAGS, "<p>#{@my_module.tags.order(:id).map(&:name).join(', ')}</p>"
    end

    def render_steps(report)
      @my_module.steps.active.ordered.each do |step|
        step_tag = build_tag('step', step.id)
        title = "<div>#{step.position_plus_one}. #{step.name}</div><div>{{#{step_tag}}}</div>"
        add_block_text(report, step_tag, title)

        # for full protocol tag
        add_block_text(report, PROTOCOL_TAG, title)

        render_elements(report, step.step_orderable_elements, [PROTOCOL_TAG, step_tag])
        clear_tags(report, PROTOCOL_TAG, step_tag)
      end
    end

    def render_results(report)
      @my_module.results.active.order(:created_at).each do |result|
        result_tag = build_tag('result', result.id)
        add_block_text(report, result_tag, "<div>#{result.name}</div><div>{{#{result_tag}}}</div>")
        render_elements(report, result.result_orderable_elements, [result_tag])
        clear_tags(report, result_tag)
      end
    end

    def render_elements(report, elements, block_element)
      elements.order(:position).each do |element|
        orderable = element.orderable
        next if orderable.archived

        element_tag = build_tag(element.orderable_type.underscore, element_id(element))

        case element.orderable_type
        when 'StepText', 'ResultText'
          render_text_element(report, element_tag, orderable, block_element)
        when 'StepTable', 'ResultTable'
          render_table(report, element_tag, orderable.table, block_element)
        when 'Checklist'
          render_checklist(report, element_tag, orderable, orderable.checklist_items, block_element)
        when 'FormResponse'
          render_form_response(report, orderable, block_element + [element_tag])
          clear_tags(report, element_tag)
        end
      end
    end

    def render_text_element(report, text_tag, text_element, block_element)
      text = insert_tiny_mce_asset_placeholders(text_element.text, text_element.tiny_mce_assets)

      # Specific element placeholder
      add_block_text(report, text_tag, "<div>#{text_element.name}</div><div>{{#{text_tag}}}</div>")
      add_block_text(report, text_tag, text)

      # Add element to block element like PROTOCOL, STEP or RESULT
      block_element.each do |element|
        add_block_text(report, element, "<div>#{text_element.name}</div><div>{{#{element}}}</div>")
        add_block_text(report, element, "<div>#{text}</div><div>{{#{element}}}</div>")
      end
    end

    def render_table(report, table_tag, table, block_element)
      table_data = table.table_data.merge(table_name: table.name)

      # Specific element placeholder
      add_block_text(report, table_tag, "<div>#{table.name}</div><div>{{#{table_tag}}}</div>")
      report.add_table_from_data table_tag, table_data

      # Add element to block element like PROTOCOL, STEP or RESULT
      block_element.each do |element|
        nested = nested_tag(element, table_tag)
        add_block_text(report, element, "<div>#{table.name}</div><div>{{#{nested}}}</div><div>{{#{element}}}</div>")
        report.add_table_from_data nested, table_data
      end
    end

    def render_checklist(report, checklist_tag, checklist, checklist_items, block_element)
      checklist_items_pairs = checklist_items&.map { |item| [item[:text], item[:checked]] }
      checklist_name_div = checklist ? "<div>#{checklist.name}</div>" : ''

      # Specific element placeholder
      add_block_text(report, checklist_tag, "#{checklist_name_div}<div>{{#{checklist_tag}}}</div>")
      report.add_checklist(checklist_tag, checklist_items_pairs, checked_symbol: CHECKED_SYMBOL)

      # Add element to block element like PROTOCOL, STEP or FORM
      block_element.each do |element|
        nested = nested_tag(element, checklist_tag)
        add_block_text(report, element, "#{checklist_name_div}<div>{{#{nested}}}</div><div>{{#{element}}}</div>")
        report.add_checklist(nested, checklist_items_pairs, checked_symbol: CHECKED_SYMBOL)
      end
    end

    def render_form_response(report, form_response, block_element)
      # Add element to block element like PROTOCOL, STEP or FORM
      block_element.each { |element| add_block_text(report, element, "<div>#{form_response.form.name}</div><div>{{#{element}}}</div>") }

      form_field_values = form_response.form_field_values.where(latest: true).index_by(&:form_field_id)

      form_response.form.form_fields.order(:position)&.each do |form_field|
        form_field_value = form_field_values[form_field.id]
        tag = I18n.t('protocols.report_template.data_inputs.codes.tag_form_field', form_id: form_response.id, id: form_field.id).to_sym

        value = if form_field_value&.not_applicable
                  I18n.t('forms.export.values.not_applicable')
                elsif form_field_value.is_a?(FormTextFieldValue)
                  SmartAnnotations::TagToText.new(@user, @team, form_field_value&.formatted).text
                elsif form_field_value.is_a?(FormDatetimeFieldValue)
                  form_field_value&.formatted_localize
                elsif form_field_value.is_a?(FormRepositoryRowsFieldValue)
                  form_repository_rows_field_value_formatter(form_field_value, @user)
                elsif form_field[:data]['type'] == 'MultipleChoiceField'
                  form_field[:data]['options']&.map { |option| { text: option, checked: form_field_value&.value&.include?(option) } }
                elsif form_field[:data]['type'] == 'SingleChoiceField'
                  form_field[:data]['options']&.map { |option| { text: option, checked: form_field_value&.value == option } }
                else
                  form_field_value&.formatted
                end

        if !form_field_value&.not_applicable && %w(MultipleChoiceField SingleChoiceField).include?(form_field[:data]['type'])
          render_checklist(report, tag, nil, value, block_element)
        else
          # Specific element placeholder
          report.add_field tag, value

          # Add element to block element like PROTOCOL, STEP or FORM
          block_element.each do |element|
            add_block_text(report, element, "<div>#{value}</div><div>{{#{element}}}</div>")
          end
        end
      end
    end

    def insert_tiny_mce_asset_placeholders(text, attached_tiny_mce_assets)
      html_text = Nokogiri::HTML(text)

      attached_tiny_mce_assets.each do |tiny_mce_asset|
        next unless tiny_mce_asset&.image&.attached?

        tiny_mce_asset_elms = html_text.search("img[data-mce-token=\"#{Base62.encode(tiny_mce_asset.id)}\"]")
        next if tiny_mce_asset_elms.blank?

        begin
          variant = tiny_mce_asset.image.variant(resize_to_limit: Constants::LARGE_PIC_FORMAT).processed
          width = tiny_mce_asset_elms[0].attributes['width']&.value&.to_i
          height = tiny_mce_asset_elms[0].attributes['height']&.value&.to_i
          unless width && height
            variant.blob.analyze unless variant.blob.metadata['width'] && variant.blob.metadata['height']
            width = variant.blob.metadata['width']
            height = variant.blob.metadata['height']
          end

          tempfile = Tempfile.new([variant.blob.filename.base, variant.blob.filename.extension_with_delimiter], Rails.root.join('tmp'), binmode: true)
          variant.blob.download { |chunk| tempfile.write(chunk) }
          tempfile.flush
          tempfile.rewind

          @tiny_mce_assets << { id: tiny_mce_asset.id, file: tempfile, width: width, height: height }

          tiny_mce_asset_elms.each { |el| el.replace(html_text.create_text_node("{{TINY_MCE_ASSET_#{tiny_mce_asset.id}}}")) }
        rescue StandardError => e
          Rails.logger.error(e.message)
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end

      html_text&.at('body')&.inner_html.to_s
    end

    def element_id(element)
      case element.orderable_type
      when 'StepTable', 'ResultTable'
        element.orderable.table.id
      else
        element.orderable.id
      end
    end

    # Protocol, text, table, checklist and form content always starts on its own line,
    # even when its tag is placed inline in the template
    def add_block_text(report, tag, html)
      report.add_text tag, html, display: :block
    end

    def build_tag(type, id)
      I18n.t('protocols.report_template.data_inputs.codes.tag_content', content_type: I18n.t("protocols.report_template.data_inputs.codes.type.#{type}"), id: id).to_sym
    end

    def nested_tag(element, tag)
      :"#{element}_#{tag}"
    end

    def clear_tags(report, *tags)
      tags.each { |tag| report.add_field tag, '' }
    end
  end
end
