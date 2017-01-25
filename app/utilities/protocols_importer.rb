module ProtocolsImporter
  include RenamingUtil

  def import_new_protocol(protocol_json, team, type, user)
    remove_empty_inputs(protocol_json)
    protocol = Protocol.new(
      name: protocol_json["name"],
      description: protocol_json["description"],
      authors: protocol_json["authors"],
      protocol_type: (type == :public ? :in_repository_public : :in_repository_private),
      published_on: (type == :public ? Time.now : nil),
      added_by: user,
      team: @team
    )

    # Try to rename record
    if protocol.invalid? then
      rename_record(protocol, :name)
    end

    # Okay, now save the protocol
    protocol.save!

    # Protocol is saved, populate it
    populate_protocol(protocol, protocol_json, user)

    return protocol
  end

  def import_into_existing(protocol, protocol_json, user)
    # Firstly, destroy existing protocol's contents
    protocol.destroy_contents(user)
    protocol.reload

    # Alright, now populate the protocol
    populate_protocol(protocol, protocol_json, user)
    protocol.reload

    # Unlink the protocol
    protocol.unlink
    protocol
  end

  private

  def populate_protocol(protocol, protocol_json, user)
    protocol.reload

    asset_ids = []
    step_pos = 0
    # Check if protocol has steps
    if protocol_json['steps']
      protocol_json['steps'].values.each do |step_json|
      step = Step.create!(
        name: step_json['name'],
        description: step_json['description'],
        position: step_pos,
        completed: false,
        user: user,
        last_modified_by: user,
        protocol: protocol
      )
      step_pos += 1

      if step_json["checklists"]
        step_json["checklists"].values.each do |checklist_json|
          checklist = Checklist.create!(
            name: checklist_json["name"],
            step: step,
            created_by: user,
            last_modified_by: user
          )
          if checklist_json["items"]
            item_pos = 0
            checklist_json["items"].values.each do |item_json|
              item = ChecklistItem.create!(
                text: item_json["text"],
                checked: false,
                position: item_pos,
                created_by: user,
                last_modified_by: user,
                checklist: checklist
              )
              item_pos += 1
            end
          end
        end
      end

      if step_json['tables']
        step_json['tables'].values.each do |table_json|
          table = Table.create!(
            name: table_json['name'],
            contents: Base64.decode64(table_json['contents']),
            created_by: user,
            last_modified_by: user
          )
          StepTable.create!(
            step: step,
            table: table
          )
        end
      end

      if step_json["assets"]
        step_json["assets"].values.each do |asset_json|
          asset = Asset.new(
            created_by: user,
            last_modified_by: user
          )

          # Decode the file bytes
          asset.file = StringIO.new(Base64.decode64(asset_json["bytes"]))
          asset.file_file_name = asset_json["fileName"]
          asset.file_content_type = asset_json["fileType"]
          asset.save!
          asset_ids << asset.id

          StepAsset.create!(
            step: step,
            asset: asset
          )
        end
      end
    end
    end

    # Post process assets
    asset_ids.each do |asset_id|
      Asset.find(asset_id).post_process_file(protocol.team)
    end
  end

  def remove_empty_inputs(obj)
    obj.keys.each do |key|
      if obj[key] == ""
        obj[key] = nil
      elsif obj[key].kind_of? Hash
        # Recursive call
        remove_empty_inputs(obj[key])
      end
    end
  end

end
