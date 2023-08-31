# frozen_string_literal: true

class ProjectsJsonExportJob < ApplicationJob
  def perform(task_ids, callback, user_id)
    user = User.find(user_id)
    projects_json_export_service = ProjectsJsonExportService.new(task_ids,
                                                                 callback,
                                                                 user)
    projects_json_export_service.generate_data
    projects_json_export_service.post_request
  end
end
