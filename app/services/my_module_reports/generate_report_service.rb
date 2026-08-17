# frozen_string_literal: true

module MyModuleReports
  class GenerateReportService
    include FormFieldValuesHelper

    PROTOCOL_TAG = :PROTOCOL

    def initialize(protocol, report_template, team, user)
      @report_template = report_template
      @protocol = protocol
      @my_module = protocol.my_module
      @team = team
      @user = user
      @tiny_mce_assets = []
    end

    def call(my_module_report)
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
          report.add_inline_image "TINY_MCE_ASSET_#{tiny_mce_asset[:id]}".to_sym, tiny_mce_asset[:file].path, width: tiny_mce_asset[:width], height: tiny_mce_asset[:height]
        end

        report.generate(output.path)
        my_module_report.report.attach(io: File.open(output.path), filename: original_blob.filename, content_type: original_blob.content_type)
      end
    ensure
      @tiny_mce_assets.each do |tiny_mce_asset|
        tiny_mce_asset[:file]&.close
        tiny_mce_asset[:file]&.unlink
      end
      output.close
      output.unlink
    end

    private

    def render_general(report)
      report.add_field :TASKNAME, @my_module.name
      report.add_field :TASKDUEDATE, @my_module.due_date ? I18n.l(@my_module.due_date, format: :full) : ''

      tags = @my_module.tags.order(:id).map(&:name)

      report.add_text :TASKTAGS, tags ? "<p>#{tags.join(' ')}</p>" : ''
    end

    def render_steps(report)
      @my_module.steps.ordered.each do |step|
        report.add_field build_tag('step', step.id).to_sym, step.name

        # for full protocol tag
        report.add_text PROTOCOL_TAG, "<div>#{step.position + 1}. #{step.name}</div><div>{{#{PROTOCOL_TAG}}}</div>"

        step.step_orderable_elements.order(:position).each do |element|
          element_type = element.orderable_type
          element_tag = build_tag(element_type.underscore, element_id(element))

          case element.orderable_type
          when 'StepText'
            render_text_element(report, element_tag, element.orderable, with_protocol: true)
          when 'StepTable'
            render_table(report, element_tag, element.orderable.table, with_protocol: true)
          when 'Checklist'
            render_checklist(report, element_tag, element.orderable, element.orderable.checklist_items)
          when 'FormResponse'
            render_form_response(report, element_tag, element.orderable)
          end
        end

        report.add_field PROTOCOL_TAG, ''
      end
    end

    def render_results(report)
      @my_module.results.order(:created_at).each do |result|
        report.add_field build_tag('result', result.id).to_sym, result.name

        result.result_orderable_elements.order(:position).each do |element|
          element_type = element.orderable_type
          element_tag = build_tag(element_type.underscore, element_id(element))

          case element.orderable_type
          when 'ResultText'
            render_text_element(report, element_tag, element.orderable)
          when 'ResultTable'
            render_table(report, element_tag, element.orderable.table)
          end
        end
      end
    end

    def render_text_element(report, text_tag, text_element, with_protocol: false)
      report.add_text text_tag, "<div>#{text_element.name}</div><div>{{#{text_tag}}}</div>"
      report.add_text text_tag, insert_tiny_mce_asset_placeholders(text_element.text, text_element.tiny_mce_assets)

      # for full protocol tag
      if with_protocol
        report.add_text PROTOCOL_TAG, "<div>#{text_element.name}</div><div>{{#{PROTOCOL_TAG}}}</div>"
        report.add_text PROTOCOL_TAG, "<div>#{insert_tiny_mce_asset_placeholders(text_element.text, text_element.tiny_mce_assets)}</div><div>{{#{PROTOCOL_TAG}}}</div>"
      end
    end

    def render_table(report, table_tag, table, with_protocol: false)
      table_data = table.table_data
      table_data[:table_name] = table.name

      report.add_text table_tag, "<div>#{table.name}</div><div>{{#{table_tag}}}</div>"
      report.add_table_from_data table_tag, table_data

      # for full protocol tag
      if with_protocol
        protocol_table_tag = :PROTOCOL_TABLE
        report.add_text PROTOCOL_TAG, "<div>#{table.name}</div><div>{{#{protocol_table_tag}}}</div><div>{{#{PROTOCOL_TAG}}}</div>"
        report.add_table_from_data protocol_table_tag, table_data
      end
    end

    def render_checklist(report, checklist_tag, checklist, checklist_items)
      checklist_items_pairs = checklist_items.map { |item| [item[:text], item[:checked]] }
      checklist_name_div = checklist ? "<div>#{checklist.name}</div>" : ''

      report.add_text checklist_tag, "#{checklist_name_div}<div>{{#{checklist_tag}}}</div>"
      report.add_checklist(checklist_tag, checklist_items_pairs)

      # for full protocol tag
      protocol_checklist_tag = :PROTOCOL_CHECKLIST
      report.add_text PROTOCOL_TAG, "#{checklist_name_div}<div>{{#{protocol_checklist_tag}}}</div><div>{{#{PROTOCOL_TAG}}}</div>"
      report.add_checklist(protocol_checklist_tag, checklist_items_pairs)
    end

    def render_form_response(report, form_response_tag, form_response)
      report.add_field form_response_tag, form_response.form.name

      # for full protocol tag
      report.add_text PROTOCOL_TAG, "<div>#{form_response.form.name}</div><div>{{#{PROTOCOL_TAG}}}</div>"

      form_fields = form_response.form.form_fields.order(:position)
      form_field_values = form_response.form_field_values

      form_fields&.each do |form_field|
        form_field_value = form_field_values.find_by(form_field_id: form_field.id, latest: true)
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
                  form_field[:data]['options'].map { |option| { text: option, checked: form_field_value&.value&.include?(option) } }
                else
                  form_field_value&.formatted
                end

        if !form_field_value&.not_applicable && form_field[:data]['type'] == 'MultipleChoiceField'
          render_checklist(report, tag, nil, value)
        else
          report.add_field tag, value
          report.add_text PROTOCOL_TAG, "<div>#{value}</div><div>{{#{PROTOCOL_TAG}}}</div>"
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

    def element_label(element)
      case element.orderable_type
      when 'StepTable', 'ResultTable'
        element.orderable.table.name
      else
        element.orderable.name
      end
    end

    def build_tag(type, id)
      I18n.t('protocols.report_template.data_inputs.codes.tag_content', content_type: I18n.t("protocols.report_template.data_inputs.codes.type.#{type}"), id: id)
    end

    def build_table_data(element)
      table_data = JSON.parse(Class.new.extend(InputSanitizeHelper).smart_annotation_text(element.contents_utf_8, sanitize_text: false))['data']
      table_data = add_headers_to_table(table_data, element.well_plate?)

      table = '<table>'
      table_data.each_with_index do |row, index|
        table_tag = index.zero? ? 'th' : 'td'
        table += "<tr>#{row.map { |el| "<#{table_tag}>#{el}</#{table_tag}>" }.join}</tr>"
      end
      table += '</table>'

      table
    end

    def add_headers_to_table(table, is_well_plate)
      table&.each_with_index do |row, index|
        row.unshift(is_well_plate ? convert_index_to_letter(index) : index + 1)
      end

      header_row = Array.new(table&.dig(0)&.length || 0) do |index|
        next '' if index.zero?

        is_well_plate ? index : convert_index_to_letter(index - 1)
      end
      table&.unshift(header_row)
    end

    def convert_index_to_letter(index)
      ord_a = 'A'.ord
      ord_z = 'Z'.ord
      len = (ord_z - ord_a) + 1
      num = index

      col_name = ''
      while num >= 0
        col_name = ((num % len) + ord_a).chr + col_name
        num = (num / len).floor - 1
      end
      col_name
    end
  end
end
