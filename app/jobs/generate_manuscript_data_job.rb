# frozen_string_literal: true

class GenerateManuscriptDataJob < ApplicationJob
  def perform(project_id, experiment_ids, task_ids, callback)
    generate_manuscript_data_service = GenerateManuscriptDataService.new(project_id,
                                                                         experiment_ids,
                                                                         task_ids,
                                                                         callback)
    generate_manuscript_data_service.generate_data
    generate_manuscript_data_service.post_request
  end
end
