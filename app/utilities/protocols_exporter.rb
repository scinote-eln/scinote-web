module ProtocolsExporter
  private

  def get_guid(id)
    str1 = '00000000-0000-'
    str2 = id.to_s
    str2 = '0' * (19 - str2.size) + str2
    str2 = '4' + str2
    str2n = str2[0..3] + '-' + str2[4..7] + '-' + str2[8..-1]
    str1 + str2n
  end

  def get_protocol_name(protocol)
    ## "Inject" module's name
    protocol_name = if protocol.in_module? && protocol.name.blank?
                      protocol.my_module.name
                    else
                      protocol.name
                    end
    protocol_name
  end

  def generate_envelope_xml(protocols)
    envelope_xml = "<envelope xmlns=\"http://www.scinote.net\" " \
                   "version=\"1.0\">\n"
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

  def tiny_mce_asset_present?(object)
    object.tiny_mce_assets.exists?
  end

  def get_tiny_mce_assets(text)
    return unless text

    regex = Constants::TINY_MCE_ASSET_REGEX
    tiny_assets_xml = "<descriptionAssets>\n"
    text.gsub(regex) do |el|
      match = el.match(regex)
      img = TinyMceAsset.find_by_id(Base62.decode(match[1]))
      next unless img

      img_guid = get_guid(img.id)
      asset_file_name = "rte-#{img_guid}#{File.extname(img.file_name)}"
      asset_xml = "<tinyMceAsset tokenId=\"#{match[1]}\" id=\"#{img.id}\" guid=\"#{img_guid}\" " \
                  "fileRef=\"#{asset_file_name}\">\n"
      asset_xml << "<fileName>#{img.file_name}</fileName>\n"
      asset_xml << "<fileType>#{img.content_type}</fileType>\n"
      asset_xml << "<fileMetadata><!--[CDATA[  #{img.image.metadata.to_json}  ]]--></fileMetadata>\n"
      asset_xml << "</tinyMceAsset>\n"
      tiny_assets_xml << asset_xml
    end
    tiny_assets_xml << "</descriptionAssets>\n"
    tiny_assets_xml
  end

  def generate_protocol_xml(protocol)
    protocol_name = get_protocol_name(protocol)
    protocol_xml = "<eln xmlns=\"http://www.scinote.net\" version=\"1.0\">\n"
    protocol_xml << "<protocol id=\"#{protocol.id}\" " \
                    "guid=\"#{get_guid(protocol.id)}\">\n"
    protocol_xml << "<name>#{protocol_name}</name>\n"
    protocol_xml << "<authors>#{protocol.authors}</authors>\n"
    protocol_xml << "<description>
    <!--[CDATA[  #{Nokogiri::HTML::DocumentFragment.parse(protocol.description)}  ]]-->
    </description>\n"
    if tiny_mce_asset_present?(protocol) && protocol.description
      protocol_xml << get_tiny_mce_assets(protocol.description)
    end
    protocol_xml << "<created_at>#{protocol.created_at.as_json}</created_at>\n"
    protocol_xml << "<updated_at>#{protocol.updated_at.as_json}</updated_at>\n"

    # Steps
    if protocol.steps.count > 0
      protocol_xml << "<steps>\n"
      protocol.steps.order(:id).each do |step|
        step_guid = get_guid(step.id)
        step_xml = "<step id=\"#{step.id}\" guid=\"#{step_guid}\" " \
                   "position=\"#{step.position}\">\n"
        step_xml << "<name>#{step.name}</name>\n"
        # uses 2 spaces to make more difficult to remove user data on import
        step_xml << "<description><!--[CDATA[  #{Nokogiri::HTML::DocumentFragment.parse(step.description)}  ]]--></description>\n"

        if tiny_mce_asset_present?(step)
          step_xml << get_tiny_mce_assets(step.description)
        end
        # Assets
        if step.assets.count > 0
          step_xml << "<assets>\n"
          step.assets.order(:id).each do |asset|
            asset_guid = get_guid(asset.id)
            asset_file_name = "#{asset_guid}" \
                              "#{File.extname(asset.file_name)}"
            asset_xml = "<asset id=\"#{asset.id}\" guid=\"#{asset_guid}\" " \
                        "fileRef=\"#{asset_file_name}\">\n"
            asset_xml << "<fileName>#{asset.file_name}</fileName>\n"
            asset_xml << "<fileType>#{asset.content_type}</fileType>\n"
            asset_xml << "<fileMetadata><!--[CDATA[  #{asset.file.metadata.to_json}  ]]--></fileMetadata>\n"
            asset_xml << "</asset>\n"
            step_xml << asset_xml
          end
          step_xml << "</assets>\n"
        end

        # Tables
        if step.tables.count > 0
          step_xml << "<elnTables>\n"
          step.tables.order(:id).each do |table|
            table_xml = "<elnTable id=\"#{table.id}\" guid=\"#{get_guid(table.id)}\">\n"
            table_xml << "<name>#{table.name}</name>\n"
            table_xml << "<contents>#{table.contents.unpack1('H*')}</contents>\n"
            table_xml << "</elnTable>\n"
            step_xml << table_xml
          end
          step_xml << "</elnTables>\n"
        end

        # Checklists
        if step.checklists.count > 0
          step_xml << "<checklists>\n"
          step.checklists.order(:id).each do |checklist|
            checklist_xml = "<checklist id=\"#{checklist.id}\" " \
                            "guid=\"#{get_guid(checklist.id)}\">\n"
            checklist_xml << "<name>#{checklist.name}</name>\n"
            if checklist.checklist_items
              checklist_xml << "<items>\n"
              checklist.checklist_items.each do |item|
                item_xml = "<item id=\"#{item.id}\" " \
                           "guid=\"#{get_guid(item.id)}\" " \
                           "position=\"#{item.position}\">\n"
                item_xml << "<text>#{item.text}</text>\n"
                item_xml << "</item>\n"
                checklist_xml << item_xml
              end
              checklist_xml << "</items>\n"
            end
            checklist_xml << "</checklist>\n"
            step_xml << checklist_xml
          end
          step_xml << "</checklists>\n"
        end
        protocol_xml << step_xml
        protocol_xml << "</step>\n"
      end
      protocol_xml << "</steps>\n"
    end
    protocol_xml << "</protocol>\n"
    protocol_xml << '</eln>'
    protocol_xml
  end

  def generate_envelope_xsd
    envelope_xsd = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    envelope_xsd << "<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\"" \
                    " elementFormDefault=\"qualified\" " \
                    "attributeFormDefault=\"unqualified\">\n"
    envelope_xsd << "<xs:element name=\"envelope\">\n"
    envelope_xsd << "<xs:complexType>\n"
    envelope_xsd << "<xs:sequence>\n"
    envelope_xsd << "<xs:element name=\"protocol\" maxOccurs=\"unbounded\">\n"
    envelope_xsd << "<xs:complexType>\n"
    envelope_xsd << "<xs:simpleContent>\n"
    envelope_xsd << "<xs:extension base=\"xs:string\">\n"
    envelope_xsd << "<xs:attribute name=\"id\" type=\"xs:int\" " \
                    "use=\"required\"></xs:attribute>\n"
    envelope_xsd << "<xs:attribute name=\"guid\" type=\"xs:string\" " \
                    "use=\"required\"></xs:attribute>\n"
    envelope_xsd << "</xs:extension>\n"
    envelope_xsd << "</xs:simpleContent>\n"
    envelope_xsd << "</xs:complexType>\n"
    envelope_xsd << "</xs:element>\n"
    envelope_xsd << "</xs:sequence>\n"
    envelope_xsd << "<xs:attribute name=\"xmlns\" type=\"xs:string\" " \
                    "use=\"required\"></xs:attribute>\n"
    envelope_xsd << "<xs:attribute name=\"version\" type=\"xs:string\" " \
                    "use=\"required\"></xs:attribute>\n"
    envelope_xsd << "</xs:complexType>\n"
    envelope_xsd << "</xs:element>\n"
    envelope_xsd << "</xs:schema>\n"
    envelope_xsd
  end

  def generate_eln_xsd
    eln_xsd = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    eln_xsd << "<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" " \
               "elementFormDefault=\"qualified\" " \
               "attributeFormDefault=\"unqualified\">\n"
    eln_xsd << "<xs:element name=\"eln\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:all>\n"
    eln_xsd << "<xs:element name=\"protocol\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:all>\n"
    eln_xsd << "<xs:element name=\"name\" type=\"xs:string\"></xs:element>\n"
    eln_xsd << "<xs:element name=\"authors\" type=\"xs:string\" " \
               "minOccurs=\"0\"></xs:element>\n"
    eln_xsd << "<xs:element name=\"description\" type=\"xs:string\" " \
               "minOccurs=\"0\"></xs:element>\n"
    eln_xsd << "<xs:element name=\"created_at\" " \
               "type=\"xs:string\"></xs:element>\n"
    eln_xsd << "<xs:element name=\"updated_at\" " \
               "type=\"xs:string\"></xs:element>\n"
    eln_xsd << "<xs:element name=\"steps\" minOccurs=\"0\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:sequence>\n"
    eln_xsd << "<xs:element name=\"step\" maxOccurs=\"unbounded\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:all>\n"
    eln_xsd << "<xs:element name=\"name\" type=\"xs:string\"></xs:element>\n"
    eln_xsd << "<xs:element name=\"description\" type=\"xs:string\" " \
               "minOccurs=\"0\"></xs:element>\n"
    eln_xsd << "<xs:element name=\"checklists\" minOccurs=\"0\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:sequence>\n"
    eln_xsd << "<xs:element name=\"checklist\" maxOccurs=\"unbounded\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:all>\n"
    eln_xsd << "<xs:element name=\"name\" type=\"xs:string\"></xs:element>\n"
    eln_xsd << "<xs:element name=\"items\" minOccurs=\"0\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:sequence>\n"
    eln_xsd << "<xs:element name=\"item\" maxOccurs=\"unbounded\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:all>\n"
    eln_xsd << "<xs:element name=\"text\" type=\"xs:string\"></xs:element>\n"
    eln_xsd << "</xs:all>\n"
    eln_xsd << "<xs:attribute name=\"id\" type=\"xs:int\" use=\"required\">" \
               "</xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"guid\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"position\" type=\"xs:int\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:sequence>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:all>\n"
    eln_xsd << "<xs:attribute name=\"id\" type=\"xs:int\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"guid\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:sequence>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "<xs:element name=\"descriptionAssets\" minOccurs=\"0\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:sequence>\n"
    eln_xsd << "<xs:element name=\"tinyMceAsset\" maxOccurs=\"unbounded\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:all>\n"
    eln_xsd << "<xs:element name=\"fileName\" " \
               "type=\"xs:string\"></xs:element>\n"
    eln_xsd << "<xs:element name=\"fileType\" " \
               "type=\"xs:string\"></xs:element>\n"
    eln_xsd << "</xs:all>\n"
    eln_xsd << "<xs:attribute name=\"id\" type=\"xs:int\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"tokenId\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"guid\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"fileRef\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:sequence>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "<xs:element name=\"assets\" minOccurs=\"0\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:sequence>\n"
    eln_xsd << "<xs:element name=\"asset\" maxOccurs=\"unbounded\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:all>\n"
    eln_xsd << "<xs:element name=\"fileName\" " \
               "type=\"xs:string\"></xs:element>\n"
    eln_xsd << "<xs:element name=\"fileType\" " \
               "type=\"xs:string\"></xs:element>\n"
    eln_xsd << "</xs:all>\n"
    eln_xsd << "<xs:attribute name=\"id\" type=\"xs:int\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"guid\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"fileRef\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:sequence>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "<xs:element name=\"elnTables\" minOccurs=\"0\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:sequence>\n"
    eln_xsd << "<xs:element name=\"elnTable\" maxOccurs=\"unbounded\">\n"
    eln_xsd << "<xs:complexType>\n"
    eln_xsd << "<xs:all>\n"
    eln_xsd << "<xs:element name=\"contents\" " \
               "type=\"xs:string\"></xs:element>\n"
    eln_xsd << "</xs:all>\n"
    eln_xsd << "<xs:attribute name=\"id\" type=\"xs:int\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"guid\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:sequence>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:all>\n"
    eln_xsd << "<xs:attribute name=\"id\" type=\"xs:int\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"guid\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"position\" type=\"xs:int\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:sequence>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:all>\n"
    eln_xsd << "<xs:attribute name=\"id\" type=\"xs:int\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"guid\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:all>\n"
    eln_xsd << "<xs:attribute name=\"xmlns\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "<xs:attribute name=\"version\" type=\"xs:string\" " \
               "use=\"required\"></xs:attribute>\n"
    eln_xsd << "</xs:complexType>\n"
    eln_xsd << "</xs:element>\n"
    eln_xsd << "</xs:schema>\n"
  end
end
