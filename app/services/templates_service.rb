# frozen_string_literal: true

class TemplatesService
  def initialize(base_dir = nil)
    @base_dir = base_dir ? base_dir : "#{Rails.root}/app/assets/templates"
    templates_dir_pattern = "#{@base_dir}/experiment_*/"
    @experiment_templates = {}
    Dir.glob(templates_dir_pattern).each do |tmplt_dir|
      id = /[0-9]+/.match(tmplt_dir.split('/').last)[0]
      uuid = /\"uuid\":\"([a-fA-F0-9\-]{36})\"/
             .match(File.read(tmplt_dir + 'experiment.json'))[1]
      @experiment_templates[uuid] = id.to_i
    end
  end

  def update_project(project)
    return unless project.template
    owner = project.user_projects
                   .where(role: 'owner')
                   .order(:created_at)
                   .first
                   .user
    return unless owner.present?
    updated = false
    exp_tmplt_dir_prefix = "#{@base_dir}/experiment_"
    existing = project.experiments.where.not(uuid: nil).pluck(:uuid)
    @experiment_templates.except(*existing).each_value do |id|
      importer_service = TeamImporter.new
      importer_service.import_experiment_template_from_dir(
        exp_tmplt_dir_prefix + id.to_s, project.id, owner.id
      )
      updated = true
    end
    updated
  end

  def update_all_projects
    processed_counter = 0
    updated_counter = 0
    Project.where(template: true).find_each do |project|
      processed_counter += 1
      updated_counter += 1 if update_project(project)
    end
    [updated_counter, processed_counter]
  end
end
