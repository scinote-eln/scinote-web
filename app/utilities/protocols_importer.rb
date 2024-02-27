# frozen_string_literal: true

class ProtocolsImporter
  include RenamingUtil

  def initialize(user, team)
    @user = user
    @team = team
  end

  def import_new_protocol(protocol_json)
    remove_empty_inputs(protocol_json)
    protocol = Protocol.new(
      name: protocol_json['name'],
      authors: protocol_json['authors'],
      protocol_type: :in_repository_draft,
      added_by: @user,
      team: @team
    )

    # Try to rename record
    rename_record(protocol, :name) if protocol.invalid?

    # Okay, now save the protocol
    protocol.save!

    # Protocol is saved, populate it
    populate_protocol(protocol, protocol_json)

    protocol
  end

  def import_into_existing(protocol, protocol_json)
    # Firstly, destroy existing protocol's contents
    protocol.tiny_mce_assets.destroy_all
    protocol.destroy_contents
    protocol.reload

    # Alright, now populate the protocol
    populate_protocol(protocol, protocol_json)
    protocol.reload

    # Unlink the protocol
    protocol.unlink
    protocol
  end

  private

  def create_in_step!(step, new_orderable)
    new_orderable.save!

    step.step_orderable_elements.create!(
      position: step.step_orderable_elements.length,
      orderable: new_orderable
    )
  end

  def populate_protocol(protocol, protocol_json)
    protocol.reload
    protocol.description = populate_rte(protocol_json, protocol)
    protocol.name = protocol_json['name'].presence
    protocol.save!
    asset_ids = []
    step_pos = 0
    # Check if protocol has steps
    protocol_json['steps']&.values&.each do |step_json|
      step = Step.create!(
        name: step_json['name'],
        position: step_pos,
        completed: false,
        user: @user,
        last_modified_by: @user,
        protocol: protocol
      )
      # need step id to link image to step
      step_description_text = step.step_texts.create
      step_description_text.update(text: populate_rte(step_json, step_description_text))
      create_in_step!(step, step_description_text)

      step.save!
      step_pos += 1

      step_json['checklists']&.values&.each do |checklist_json|
        checklist = Checklist.new(
          name: checklist_json['name'],
          step: step,
          created_by: @user,
          last_modified_by: @user
        )

        create_in_step!(step, checklist)

        next unless checklist_json['items']

        item_pos = 0
        checklist_json['items'].values.each do |item_json|
          ChecklistItem.create!(
            text: item_json['text'],
            checked: false,
            position: item_pos,
            created_by: @user,
            last_modified_by: @user,
            checklist: checklist
          )
          item_pos += 1
        end
      end

      step_json['tables']&.values&.each do |table_json|
        step_table = StepTable.new(
          step: step,
          table: Table.new(
            name: table_json['name'],
            contents: Base64.decode64(table_json['contents']),
            created_by: @user,
            last_modified_by: @user,
            team: @team
          )
        )

        create_in_step!(step, step_table)
      end

      next unless step_json['assets']

      step_json['assets']&.values&.each do |asset_json|
        asset = Asset.new(
          created_by: @user,
          last_modified_by: @user,
          team: @team
        )

        # Decode the file bytes
        asset.file.attach(io: StringIO.new(Base64.decode64(asset_json['bytes'])),
                          filename: asset_json['fileName'],
                          content_type: asset_json['fileType'],
                          metadata: JSON.parse(asset_json['fileMetadata'] || '{}'))
        asset.save!
        asset_ids << asset.id

        StepAsset.create!(
          step: step,
          asset: asset
        )
      end
    end

    # Post process assets
    asset_ids.each do |asset_id|
      Asset.find(asset_id).post_process_file
    end
  end

  def remove_empty_inputs(obj)
    obj.keys.each do |key|
      if obj[key] == ''
        obj[key] = nil
      elsif obj[key].is_a? Hash
        # Recursive call
        remove_empty_inputs(obj[key])
      end
    end
  end

  # create tiny_mce assets and change the inport tokens
  def populate_rte(object_json, object)
    return populate_rte_legacy(object_json) unless object_json['descriptionAssets']

    description = TinyMceAsset.update_old_tinymce(object_json['description'], nil, true)
    object_json['descriptionAssets'].values.each do |tiny_mce_img_json|
      tiny_mce_img = TinyMceAsset.new(
        object: object,
        team_id: @team.id,
        saved: true
      )
      tiny_mce_img.save!

      # Decode the file bytes
      file = StringIO.new(Base64.decode64(tiny_mce_img_json['bytes']))
      to_blob = ActiveStorage::Blob.create_and_upload!(io: file,
                                filename: tiny_mce_img_json['fileName'],
                                content_type: tiny_mce_img_json['fileType'],
                                metadata: JSON.parse(tiny_mce_img_json['fileMetadata'] || '{}'))
      tiny_mce_img.image.attach(to_blob)

      if description.gsub!("data-mce-token=\"#{tiny_mce_img_json['tokenId']}\"",
                           "data-mce-token=\"#{Base62.encode(tiny_mce_img.id)}\"")
      else
        description.gsub!("data-mce-token=\"#{Base62.encode(tiny_mce_img_json['tokenId'].to_i)}\"",
                          "data-mce-token=\"#{Base62.encode(tiny_mce_img.id)}\"")
      end
      description.gsub!('  ]]--&gt;', '')
    end
    description
  end

  # handle import from legacy exports
  def populate_rte_legacy(object_json)
    return unless object_json['description']&.present?

    object_json['description'].gsub(Constants::TINY_MCE_ASSET_REGEX, '')
                              .gsub('  ]]--&gt;', '')
  end
end
