# frozen_string_literal: true

module AssetsActions
  extend ActiveSupport::Concern

  def create_edit_image_activity(asset, current_user, started_editing)
    action = if started_editing == :start_editing
               t('activities.file_editing.started')
             elsif started_editing == :finish_editing
               t('activities.file_editing.finished')
             end
    if asset.step.class == Step
      protocol = asset.step.protocol
      default_step_items =
        { step: asset.step.id,
          step_position: { id: asset.step.id, value_for: 'position_plus_one' },
          asset_name: { id: asset.id, value_for: 'file_name' },
          action: action }
      if protocol.in_module?
        project = protocol.my_module.experiment.project
        team = project.team
        type_of = :edit_image_on_step
        message_items = { my_module: protocol.my_module.id }
      else
        type_of = :edit_image_on_step_in_repository
        project = nil
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
    elsif asset.result.class.base_class.name == 'ResultBase'
      result = asset.result
      parent = result.parent
      model_key = result.class.model_name.param_key

      message_items = { "#{model_key}": result.id,
                        asset_name: { id: asset.id, value_for: 'file_name' },
                        action: action }

      message_items[:protocol] = parent.id if parent.is_a?(Protocol)

      Activities::CreateActivityService
        .call(activity_type: :"edit_image_on_#{model_key}",
              owner: current_user,
              subject: result,
              team: parent.team,
              project: parent.is_a?(MyModule) ? parent.project : nil,
              message_items: message_items)
    elsif asset.repository_cell.present?
      repository = asset.repository_cell.repository_row.repository
      Activities::CreateActivityService
        .call(activity_type: :edit_image_on_inventory_item,
              owner: current_user,
              subject: repository,
              team: repository.team,
              message_items: {
                repository: repository.id,
                repository_row: asset.repository_cell.repository_row.id,
                asset_name: { id: asset.id, value_for: 'file_name' },
                action: action
              })
    end
  end
end
