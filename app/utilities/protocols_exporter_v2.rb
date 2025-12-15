module ProtocolsExporterV2
  include ProtocolsExporter

  private

  def generate_envelope_xml(protocols)
    envelope_xml = "<envelope xmlns=\"http://www.scinote.net\" " \
                   "version=\"1.2\">\n"
    protocols.each do |protocol|
      protocol = protocol.latest_published_version_or_self
      protocol_name = get_protocol_name(protocol)
      envelope_xml << "<protocol id=\"#{protocol.id}\" " \
                      "guid=\"#{get_guid(protocol.id)}\">#{protocol_name}" \
                      "</protocol>\n"
    end
    envelope_xml << "</envelope>\n"
    envelope_xml
  end

  def generate_protocol_xml(protocol)
    protocol_name = get_protocol_name(protocol)

    protocol_xml =
      "<eln xmlns=\"http://www.scinote.net\" version=\"1.2\">\n" \
      "<protocol id=\"#{protocol.id}\" guid=\"#{get_guid(protocol.id)}\">\n" \
      "<name>#{protocol_name}</name>\n" \
      "<authors>#{protocol.authors}</authors>\n" \
      "<description>" \
      "<!--[CDATA[  #{Nokogiri::HTML::DocumentFragment.parse(protocol.description)}  ]]-->" \
      "</description>\n"

    protocol_xml << get_tiny_mce_assets(protocol.description) if tiny_mce_asset_present?(protocol) && protocol.description

    protocol_xml << "<created_at>#{protocol.created_at.as_json}</created_at>\n"
    protocol_xml << "<updated_at>#{protocol.updated_at.as_json}</updated_at>\n"

    # Steps
    if protocol.steps.any?
      protocol_xml <<
        "<steps>\n" \
        "#{protocol.steps.order(:position).map { |s| step_xml(s) }.join}" \
        "</steps>\n"
    end

    protocol_xml <<
      "<resultTemplates>\n" \
      "#{export_result_templates(protocol)}" \
      "</resultTemplates>\n"

    protocol_xml << "</protocol>\n"
    protocol_xml << '</eln>'
    protocol_xml
  end

  def export_result_templates(protocol)
    if protocol.in_module?
      protocol.my_module.results.map { |result| result_template_xml(result) }.join
    else
      protocol.results.map { |result|  result_template_xml(result) }.join
    end
  end

  def result_template_xml(result)
    result_template_guid = get_guid(result.id)
    xml = "<resultTemplate id=\"#{result.id}\" guid=\"#{result_template_guid}\">\n" \
          "<name>#{result.name}</name>\n"

    # Assets
    xml << "<assets>\n#{result.assets.map { |a| asset_xml(a) }.join}</assets>\n" if result.assets.any?

    if result.result_orderable_elements.any?
      xml << "<resultElements>\n"
      result.result_orderable_elements.find_each do |result_orderable_element|
        element = result_orderable_element.orderable
        element_guid = get_guid(element.id)
        xml << "<resultElement type=\"#{result_orderable_element.orderable_type}\" guid=\"#{element_guid}\" " \
               "position=\"#{result_orderable_element.position}\">"

        case element
        when ResultText
          xml << result_text_xml(element)
        when ResultTable
          xml << table_xml(element.table)
        end
        xml << "</resultElement>\n"
      end
      xml << "</resultElements>\n"
    end

    xml << '</resultTemplate>'
    xml
  end

  def step_xml(step)
    step_guid = get_guid(step.id)
    xml = "<step id=\"#{step.id}\" guid=\"#{step_guid}\" position=\"#{step.position}\">\n" \
          "<name>#{step.name}</name>\n"

    # Assets
    xml << "<assets>\n#{step.assets.map { |a| asset_xml(a) }.join}</assets>\n" if step.assets.any?

    if step.step_orderable_elements.any?
      xml << "<stepElements>\n"
      step.step_orderable_elements.find_each do |step_orderable_element|
        element = step_orderable_element.orderable
        element_guid = get_guid(element.id)
        xml << "<stepElement type=\"#{step_orderable_element.orderable_type}\" guid=\"#{element_guid}\" " \
               "position=\"#{step_orderable_element.position}\">"

        case element
        when StepText
          xml << step_text_xml(element)
        when StepTable
          xml << table_xml(element.table)
        when Checklist
          xml << checklist_xml(element)
        when FormResponse
          xml << form_xml(element.form)
        end

        xml << "</stepElement>\n"
      end
      xml << "</stepElements>\n"
    end

    xml << '</step>'

    xml
  end

  def step_text_xml(step_text)
    xml = "<stepText id=\"#{step_text.id}\" guid=\"#{get_guid(step_text.id)}\">\n" \
          "<name>#{step_text.name}</name>\n" \
          "<contents>\n" \
          "<!--[CDATA[  #{Nokogiri::HTML::DocumentFragment.parse(step_text.text)}  ]]-->" \
          "</contents>\n"

    xml << get_tiny_mce_assets(step_text.text) if step_text.text.present?

    xml << "</stepText>\n"
  end

  def result_text_xml(result_text)
    xml = "<resultText id=\"#{result_text.id}\" guid=\"#{get_guid(result_text.id)}\">\n" \
          "<name>#{result_text.name}</name>\n" \
          "<contents>\n" \
          "<!--[CDATA[  #{Nokogiri::HTML::DocumentFragment.parse(result_text.text)}  ]]-->" \
          "</contents>\n"

    xml << get_tiny_mce_assets(result_text.text) if result_text.text.present?

    xml << "</resultText>\n"
  end

  def table_xml(table)
    "<elnTable id=\"#{table.id}\" guid=\"#{get_guid(table.id)}\">\n" \
      "<name>#{table.name}</name>\n" \
      "<contents>#{table.contents.unpack1('H*')}</contents>\n" \
      "<metadata>#{table.metadata.to_json}</metadata>\n" \
      "</elnTable>\n"
  end

  def checklist_xml(checklist)
    xml = "<checklist id=\"#{checklist.id}\" guid=\"#{get_guid(checklist.id)}\">\n" \
          "<name>#{checklist.name}</name>\n"

    xml << "<items>\n#{checklist.checklist_items.map { |ci| checklist_item_xml(ci) }.join}</items>\n" if checklist.checklist_items.any?

    xml << "</checklist>\n"

    xml
  end

  def checklist_item_xml(checklist_item)
    "<item id=\"#{checklist_item.id}\" " \
      "guid=\"#{get_guid(checklist_item.id)}\" " \
      "position=\"#{checklist_item.position}\">\n" \
      "<text>#{checklist_item.text}</text>\n" \
      "</item>\n" \
  end

  def asset_xml(asset)
    asset_guid = get_guid(asset.id)
    asset_file_name = "#{asset_guid}#{File.extname(asset.file_name)}"
    "#{asset_guid}#{File.extname(asset.file_name)}" \
      "<asset id=\"#{asset.id}\" guid=\"#{asset_guid}\" fileRef=\"#{asset_file_name}\">\n" \
      "<fileName>#{asset.file_name}</fileName>\n" \
      "<fileType>#{asset.content_type}</fileType>\n" \
      "<fileMetadata><!--[CDATA[  #{asset.file.metadata.except('version', 'restored_from_version').to_json}  ]]--></fileMetadata>\n" \
      "</asset>\n"
  end

  def prepare_asset_for_export(ostream, asset, dir)
    return unless asset.file.attached?

    asset_guid = get_guid(asset.id)
    asset_file_name = asset_guid.to_s + File.extname(asset.file_name).to_s
    ostream.put_next_entry("#{dir}/#{asset_file_name}")
    ostream.print(asset.file.download)

    return unless asset.preview_image.attached?

    asset_preview_image_name = asset_guid.to_s + File.extname(asset.preview_image_file_name).to_s
    ostream.put_next_entry("#{dir}/previews/#{asset_preview_image_name}")
    ostream.print(asset.preview_image.download)
  end

  def form_xml(form)
    "<form id=\"#{form.id}\" guid=\"#{get_guid(form.id)}\"> </form>\n" \
  end
end
