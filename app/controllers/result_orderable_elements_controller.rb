# frozen_string_literal: true

class ResultOrderableElementsController < ResultOrderableElementsBaseController

  private

  def log_activity(type_of, my_module)
    default_items = { result: @result.id }
    message_items = default_items.merge({ my_module: my_module.id })

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @result,
            team: my_module.team,
            project: my_module.experiment.project,
            message_items: message_items)
  end
end
