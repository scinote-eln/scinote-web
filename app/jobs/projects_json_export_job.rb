# frozen_string_literal: true

class ProjectsJsonExportJob < ApplicationJob
  def perform(project_id, experiment_ids, task_ids, callback)
    projects_json_export_service = ProjectsJsonExportService.new(project_id,
                                                                 experiment_ids,
                                                                 task_ids,
                                                                 callback)
    projects_json_export_service.generate_data
    projects_json_export_service.post_request
  end
end
