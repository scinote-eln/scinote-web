module ProtocolsExporter
  def export_protocols(protocols)
    protocols_json = []
    protocols.each do |protocol|
      protocols_json << export_protocol(protocol)
    end

    return protocols_json
  end

  private

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
        table_json = table.as_json(only: [ :id ])
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