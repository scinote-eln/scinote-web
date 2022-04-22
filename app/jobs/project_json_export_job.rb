# frozen_string_literal: true

class ProjectJsonExportJob < ApplicationJob
  def perform(project_id, experiment_ids, task_ids, callback)
    project_json_export_service = ProjectJsonExportService.new(project_id,
                                                               experiment_ids,
                                                               task_ids,
                                                               callback)
    project_json_export_service.generate_data
    project_json_export_service.post_request
  end
end
