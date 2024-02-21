# frozen_string_literal: true

class ProtocolsImporterV2
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
    protocol_json['name'] = protocol.name
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
      position: step.step_orderable_elements.size,
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

      step.save!
      step_pos += 1

      step_json['stepElements']&.values&.each do |element_params|
        case element_params['type']
        when 'StepText'
          create_step_text(step, element_params['stepText'])
        when 'StepTable'
          create_step_table(step, element_params['elnTable'])
        when 'Checklist'
          create_checklist(step, element_params['checklist'])
        end
      end

      next unless step_json['assets']

      asset_ids += create_assets(step_json, step)
    end

    # Post process assets
    asset_ids.each do |asset_id|
      Asset.find(asset_id).post_process_file
    end
  end

  def create_assets(step_json, step)
    asset_ids = []
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
      if asset_json['preview_image'].present?
        asset.preview_image.attach(io: StringIO.new(Base64.decode64(asset_json.dig('preview_image', 'bytes'))),
                                   filename: asset_json.dig('preview_image', 'fileName'))
      end

      asset.save!
      asset_ids << asset.id

      StepAsset.create!(
        step: step,
        asset: asset
      )
    end

    asset_ids
  end

  def create_step_text(step, params)
    step_text = StepText.create!(
      step: step
    )

    step_text.update!(text: populate_rte(params, step_text), name: params[:name])

    create_in_step!(step, step_text)
  end

  def create_step_table(step, params)
    step_table = StepTable.new(
      step: step,
      table: Table.new(
        name: params['name'],
        contents: Base64.decode64(params['contents']),
        metadata: JSON.parse(params['metadata'].presence || '{}'),
        created_by: @user,
        last_modified_by: @user,
        team: @team
      )
    )

    create_in_step!(step, step_table)
  end

  def create_checklist(step, params)
    checklist = Checklist.new(
      name: params['name'],
      step: step,
      created_by: @user,
      last_modified_by: @user
    )

    create_in_step!(step, checklist)

    return unless params['items']

    item_pos = 0

    params['items'].each_value do |item_json|
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

  def remove_empty_inputs(obj)
    obj.each_key do |key|
      case obj[key]
      when ''
        obj[key] = nil
      when Hash
        # Recursive call
        remove_empty_inputs(obj[key])
      end
    end
  end

  # create tiny_mce assets and change the import tokens
  def populate_rte(params, object)
    description = params['description'] || params['contents']

    return description unless params['descriptionAssets']

    params['descriptionAssets'].each_value do |tiny_mce_img_json|
      tiny_mce_img = TinyMceAsset.new(
        object: object,
        team_id: @team.id,
        saved: true
      )
      tiny_mce_img.save!

      # Decode the file bytes
      file = StringIO.new(Base64.decode64(tiny_mce_img_json['bytes']))
      to_blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: tiny_mce_img_json['fileName'],
        content_type: tiny_mce_img_json['fileType'],
        metadata: JSON.parse(tiny_mce_img_json['fileMetadata'] || '{}')
      )
      tiny_mce_img.image.attach(to_blob)
      description.gsub!(
        "data-mce-token=\"#{tiny_mce_img_json['tokenId']}\"",
        "data-mce-token=\"#{Base62.encode(tiny_mce_img.id)}\""
      ) || description.gsub!(
        "data-mce-token=\"#{Base62.encode(tiny_mce_img_json['tokenId'].to_i)}\"",
        "data-mce-token=\"#{Base62.encode(tiny_mce_img.id)}\""
      )
      description.gsub!('  ]]--&gt;', '')
    end
    description
  end
end
