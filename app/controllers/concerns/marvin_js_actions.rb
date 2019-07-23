# frozen_string_literal: true

module MarvinJsActions
  extend ActiveSupport::Concern

  def create_edit_marvinjs_activity(asset, current_user, started_editing)
    action = if started_editing == :start_editing
               t('activities.file_editing.started')
             elsif started_editing == :finish_editing
               t('activities.file_editing.finished')
             end
    return unless marvinjs_asset_validation(asset)

    if marvinjs_asset_type(asset, Step)
      marvinjs_step_activity(asset, current_user, 'edit', action)
    elsif marvinjs_asset_type(asset, Result)
      marvinjs_result_activity(asset, current_user, 'edit', action)
    end
  end

  def create_create_marvinjs_activity(asset, current_user)
    return unless marvinjs_asset_validation(asset)

    if marvinjs_asset_type(asset, Step)
      marvinjs_step_activity(asset, current_user, 'create')
    elsif marvinjs_asset_type(asset, Result)
      marvinjs_result_activity(asset, current_user, 'create')
    end
  end

  def create_delete_marvinjs_activity(asset, current_user)
    return unless marvinjs_asset_validation(asset)

    if marvinjs_asset_type(asset, Step)
      marvinjs_step_activity(asset, current_user, 'delete')
    elsif marvinjs_asset_type(asset, Result)
      marvinjs_result_activity(asset, current_user, 'delete')
    end
  end

  private

  def marvinjs_asset_validation(asset)
    if asset.class == Asset
      asset && asset.file.metadata[:asset_type] == 'marvinjs'
    else
      asset && asset.image.metadata[:asset_type] == 'marvinjs'
    end
  end

  def marvinjs_asset_type(asset, klass)
    if asset.class == Asset
      return true if asset.step_asset&.step.class == klass
      return true if asset.result_asset&.result.class == klass
    elsif asset.object.class == klass
      return true
    end
    false
  end

  def marvinjs_step_activity(asset, current_user, activity, action = nil)
    if asset.class == Asset
      step = asset.step_asset&.step
      protocol = step&.protocol
      asset_type = 'asset_name'
    else
      step = asset.object
      protocol = step&.protocol
      asset_type = 'tiny_mce_asset_name'
    end

    return unless step && protocol

    default_step_items =
      { step: step.id,
        step_position: { id: step.id, value_for: 'position_plus_one' },
        asset_type => { id: asset.id, value_for: 'file_name' } }
    default_step_items[:action] = action if action
    if protocol.in_module?
      project = protocol.my_module.experiment.project
      team = project.team
      type_of = (activity + '_chemical_structure_on_step').to_sym
      message_items = { my_module: protocol.my_module.id }
    else
      type_of = (activity + '_chemical_structure_on_step_in_repository').to_sym
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

  def marvinjs_result_activity(asset, current_user, activity, action = nil)
    result = asset.result_asset&.result
    my_module = result&.my_module

    return unless result && my_module

    message_items = {
      result: result.id,
      asset_name: { id: asset.id, value_for: 'file_name' }
    }
    message_items[:action] = action if action
    Activities::CreateActivityService
      .call(activity_type: (activity + '_chemical_structure_on_result').to_sym,
            owner: current_user,
            subject: result,
            team: my_module.experiment.project.team,
            project: my_module.experiment.project,
            message_items: message_items)
  end
end
