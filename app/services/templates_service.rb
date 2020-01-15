# frozen_string_literal: true

class TemplatesService
  def initialize(base_dir = nil)
    @base_dir = base_dir ? base_dir : "#{Rails.root}/app/assets/templates"
    templates_dir_pattern = "#{@base_dir}/experiment_*/"
    @experiment_templates = {}
    Dir.glob(templates_dir_pattern).each do |tmplt_dir|
      id = /[0-9]+/.match(tmplt_dir.split('/').last)[0]
      uuid = /\"uuid\": \"([a-fA-F0-9\-]{36})\"/
             .match(File.read(tmplt_dir + 'experiment.json'))[1]
      @experiment_templates[uuid] = id.to_i
    end
  end

  def update_team(team)
    tmpl_project = team.projects.where(template: true).take
    unless tmpl_project
      Project.transaction do
        tmpl_project = team.projects.create!(
          name: Constants::TEMPLATES_PROJECT_NAME,
          visibility: :visible,
          template: true
        )
        tmpl_project.user_projects.create!(user: team.created_by, role: 'owner')
      end
    end
    owner = tmpl_project.user_projects
                        .where(role: 'owner')
                        .order(:created_at)
                        .first&.user
    return unless owner.present?
    updated = false
    exp_tmplt_dir_prefix = "#{@base_dir}/experiment_"
    # Create lock in case another worker starts to update same team
    tmpl_project.with_lock do
      existing = tmpl_project.experiments.where.not(uuid: nil).pluck(:uuid)
      @experiment_templates.except(*existing).each_value do |id|
        importer_service = TeamImporter.new
        importer_service.import_experiment_template_from_dir(
          exp_tmplt_dir_prefix + id.to_s, tmpl_project.id, owner.id
        )
        updated = true
      end
    end
    updated
  end

  def update_all_templates
    processed_counter = 0
    updated_counter = 0
    Team.find_each do |team|
      processed_counter += 1
      updated_counter += 1 if update_team(team)
    end
    [updated_counter, processed_counter]
  end

  def schedule_creation_for_user(user)
    user.teams.each do |team|
      next if team.projects.where(template: true).any?

      TemplatesService.new.delay(
        queue: :templates
      ).update_team(team)
    end
  end
end
