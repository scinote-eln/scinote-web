require 'tmpdir'

module ProtocolsExporter
  def export_protocols(protocols)
    #protocols_json = []
    #protocols.each do |protocol|
    #  protocols_json << export_protocol(protocol)
    #end

    #return protocols_json

    # create temporary working dir, will be deleted in the end
    Dir.mktmpdir do |tmp_dir|
      # create dir for archive
      arch_dir = "#{tmp_dir}/protocols"
      Dir.mkdir(arch_dir)
      # create xml envelope document
      envelope_xml = "<envelope xmlns=\"http://www.scinote.net\" version=\"1.0\">\n"
      protocols.each do |protocol|
        protocol_guid = get_guid(protocol.id)
        # Create a folder for this protocol
        protocol_dir = "#{arch_dir}/#{protocol_guid}"
        Dir.mkdir(protocol_dir)
        # Protocol
        protocol_xml = "<eln xmlns=\"http://www.scinote.net\" version=\"1.0\">\n"
        protocol_xml << "<protocol id=\"#{protocol.id}\" guid=\"#{protocol_guid}\">\n"
        protocol_xml << "<name>#{protocol.name}</name>\n"
        protocol_xml << "<authors>#{protocol.authors}</authors>\n"
        protocol_xml << "<description>#{protocol.description}</description>\n"
        protocol_xml << "<created_at>#{protocol.created_at}</created_at>\n"
        protocol_xml << "<updated_at>#{protocol.updated_at}</updated_at>\n"

        # Steps
        if protocol.steps
          protocol_xml << "<steps>\n"
          protocol.steps.each do |step|
            step_guid = get_guid(step.id)
            step_xml = "<step id=\"#{step.id}\" guid=\"#{step_guid}\" position=\"#{step.position}\">\n"
            step_xml << "<name>#{step.name}</name>\n"
            step_xml << "<description>#{step.description}</description>\n"

            # Assets
            if step.assets
              p step.id
              p "assets"
              step_xml << '<assets>'
              step.assets.each do |asset|
                asset_guid = get_guid(asset.id)
                # create dir in protocol dir for assets
                step_dir = "#{protocol_dir}/#{step_guid}"
                p step_dir
                Dir.mkdir(step_dir)
                # create file for asset inside step dir
                asset_file_name = "#{step_dir}/#{asset_guid}#{File.extname(asset.file_file_name)}"
                output_file = File.open(asset_file_name, 'wb')
                input_file = asset.open
                p 'opened'
                # p input_file
                # puts `ls -la /tmp`
                #output_file.write(input_file.read)
                while buffer = input_file.read(4096)
                  output_file.write(buffer)
                end
                input_file.close
                p output_file.size
                asset_xml = "<asset id=\"#{asset.id}\" guid=\"#{asset_guid}\" fileRef=\"#{asset_file_name}\">\n"
                asset_xml << "<fileName>#{asset.file_file_name}</fileName>\n"
                asset_xml << "<fileType>#{asset.file_content_type}</fileType>\n"
                asset_xml << "</asset>\n"
                step_xml << asset_xml
              end
              step_xml << "</assets>\n"
            end

            # Tables
            if step.tables
              step_xml << "<elnTables>\n"
              step.tables.each do |table|
                table_xml = "<elnTable id=\"#{table.id}\" guid=\"#{get_guid(table.id)}\">\n"
                table_xml << "<contents>#{table.contents.unpack('H*')[0]}</contents>\n"
                table_xml << "</elnTable>\n"
                step_xml << table_xml
              end
              step_xml << "</elnTables>\n"
            end

            # Checklists
            if step.checklists
              step_xml << "<checklists>\n"
              step.checklists.each do |checklist|
                checklist_xml = "<checklist id=\"#{checklist.id}\" guid=\"#{get_guid(checklist.id)}\">\n"
                checklist_xml << "<name>#{checklist.name}</name>\n"
                if checklist.items
                  checklist_xml << "<items>\n"
                  checklist.items.each do |item|
                    item_xml = "<item id=\"#{item.id}\" guid=\"#{get_guid(item.id)}\" position=\"#{item.position}\">\n"
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
        p protocol_xml
        # Okay, we have a generated XML for
        # individual protocol, save it to protocol folder
        output_file = File.open("#{protocol_dir}/eln.xml", 'w')
        output_file.write(protocol_xml)

        # Add protocol to the envelope
        envelope_xml << "<protocol id=\"#{protocol.id}\" guid=\"#{protocol_guid}\">#{protocol.name}</protocol>\n"
      end
      envelope_xml << "</envelope>\n"

      # Save envelope to root directory in archive
      output_file = File.open("#{arch_dir}/scinote.xml", 'w')
      output_file.write(envelope_xml)
      puts `ls -la #{arch_dir}`
    end
  end

  private

  def get_guid(id)
    str1 = '00000000-0000-'
    str2 = id.to_s
    (19 - str2.size).times do
      str2 = '0' + str2
    end
    str2 = '4' + str2
    str2n = str2[0..3] + '-' + str2[4..7] + '-' + str2[8..-1]
    str1 + str2n
  end

  def export_protocol(protocol)
    protocol_json = protocol.as_json(only: [
      :id,
      :name,
      :description,
      :authors,
      :created_at,
      :updated_at
    ])

    # "Inject" module's name
    if protocol.in_module? && protocol.name.blank?
      protocol_json["name"] = protocol.my_module.name
    end

    protocol_json["steps"] = []
    protocol.steps.find_each do |step|
      step_json = step.as_json(only: [
        :id,
        :name,
        :description,
        :position
      ])

      step_json["tables"] = []
      step.tables.find_each do |table|
        table_json = table.as_json(only: [:id, :name])
        table_json["contents"] = table.contents.unpack("H*")[0]

        step_json["tables"] << table_json
      end

      step_json["assets"] = []
      step.assets.find_each do |asset|
        asset_json = asset.as_json(only: [
          :id,
          :file_file_name,
          :file_content_type
        ])
        asset_json["fileName"] = asset_json.delete("file_file_name")
        asset_json["fileType"] = asset_json.delete("file_content_type")

        # Retrieve file contents
        file = asset.open
        asset_json["bytes"] = Base64.encode64(file.read)
        file.close

        step_json["assets"] << asset_json
      end

      step_json["checklists"] = []
      step.checklists.find_each do |checklist|
        checklist_json = checklist.as_json(only: [
          :id,
          :name
        ])

        checklist_json["items"] = []
        checklist.checklist_items.find_each do |item|
          item_json = item.as_json(only: [
            :id,
            :text,
            :position
          ])

          checklist_json["items"] << item_json
        end

        step_json["checklists"] << checklist_json
      end

      protocol_json["steps"] << step_json
    end

    return protocol_json
  end
end
