# frozen_string_literal: true

module BioEddieActions
  extend ActiveSupport::Concern

  private

  def create_edit_bio_eddie_activity(asset, current_user, started_editing)
    action = case started_editing
             when :start_editing
               t('activities.file_editing.started')
             when :finish_editing
               t('activities.file_editing.finished')
             end
    return unless bio_eddie_asset_validation(asset)

    bio_eddie_find_target_object(asset, current_user, 'edit', action)
  end

  def create_create_bio_eddie_activity(asset, current_user)
    return unless bio_eddie_asset_validation(asset)

    bio_eddie_find_target_object(asset, current_user, 'create')
  end

  def create_register_bio_eddie_activity(asset, current_user)
    return unless bio_eddie_asset_validation(asset)

    bio_eddie_find_target_object(asset, current_user, 'register')
  end

  def bio_eddie_asset_validation(asset)
    asset && asset.file.metadata[:asset_type] == 'bio_eddie'
  end

  def bio_eddie_asset_type(asset, klass)
    return true if asset.step_asset&.step.instance_of?(klass)
    return true if asset.result_asset&.result.instance_of?(klass)

    false
  end

  def bio_eddie_find_target_object(asset, current_user, activity_type, action = nil)
    if bio_eddie_asset_type(asset, Step)
      bio_eddie_step_activity(asset, current_user, activity_type, action)
    elsif bio_eddie_asset_type(asset, Result)
      bio_eddie_result_activity(asset, current_user, activity_type, action)
    end
  end

  def bio_eddie_step_activity(asset, current_user, activity, action = nil)
    step = asset.step_asset&.step
    asset_type = 'asset_name'
    protocol = step&.protocol

    return unless step && protocol

    default_step_items = {
      step: step.id,
      step_position: { id: step.id, value_for: 'position_plus_one' },
      asset_type => { id: asset.id, value_for: 'file_name' },
      description: asset.blob.metadata['description'],
      name: asset.blob.metadata['name']
    }

    default_step_items[:action] = action if action
    if protocol.in_module?
      project = protocol.my_module.experiment.project
      team = project.team
      type_of = "#{activity}_molecule_on_step".to_sym
      message_items = { my_module: protocol.my_module.id }
    else
      type_of = "#{activity}_molecule_on_step_in_repository".to_sym
      team = protocol.team
      message_items = { protocol: protocol.id }
    end
    message_items = default_step_items.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: protocol,
            team: team,
            project: project,
            message_items: message_items)
  end

  def bio_eddie_result_activity(asset, current_user, activity, action = nil)
    result = asset.result_asset&.result
    asset_type = 'asset_name'
    my_module = result&.my_module

    return unless result && my_module

    message_items = {
      result: result.id,
      asset_type => { id: asset.id, value_for: 'file_name' },
      description: asset.blob.metadata['description'],
      name: asset.blob.metadata['name']
    }

    message_items[:action] = action if action
    Activities::CreateActivityService
      .call(activity_type: "#{activity}_molecule_on_result".to_sym,
            owner: current_user,
            subject: result,
            team: my_module.team,
            project: my_module.project,
            message_items: message_items)
  end
end
