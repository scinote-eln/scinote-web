require 'fileutils'

class TeamExporter
  def initialize(team_id)
    @team = Team.includes(:user_teams).find_by_id(team_id)
    raise StandardError, 'Can not load team' unless @team
    @assets_to_copy = []
    @tiny_mce_assets_to_copy = []
  end

  def export_to_dir
    @asset_counter = 0
    @team.transaction(isolation: :serializable) do
      @dir_to_export = FileUtils.mkdir_p(
        File.join("tmp/team_#{@team.id}_export_#{Time.now.to_i}")
      ).first

      # Writing JSON file with team structure
      File.write(
        File.join(@dir_to_export, 'team_export.json'),
        team(@team).to_json
      )
      # Copying assets
      copy_files(@assets_to_copy, :file, File.join(@dir_to_export, 'assets')) do
        @asset_counter += 1
      end
      # Copying tiny_mce_assets
      copy_files(@tiny_mce_assets_to_copy,
                 :image,
                 File.join(@dir_to_export, 'tiny_mce_assets'))
      puts "Exported assets: #{@asset_counter}"
      puts "Exported tinyMCE assets: #{@team.tiny_mce_assets.count}"
      puts "Exported users: #{@team.users.count}"
      puts "Exported repositories: #{@team.repositories.count}"
      puts "Exported projects: #{@team.projects.count}"
      puts 'Done!'
    end
  end

  private

  def copy_files(assets, attachment_name, dir_name)
    assets.flatten.each do |a|
      next unless a.public_send(attachment_name).present?
      unless a.public_send(attachment_name).exists?
        raise StandardError,
              "File id:#{a.id} of type #{attachment_name} is missing"
      end
      yield if block_given?
      dir = FileUtils.mkdir_p(File.join(dir_name, a.id.to_s)).first
      if ENV['S3_BUCKET']
        s3_asset =
          S3_BUCKET.object(a.public_send(attachment_name).path.remove(%r{^/}))
        file_name = a.public_send(attachment_name).original_filename
        File.open(File.join(dir, file_name), 'wb') do |f|
          s3_asset.get(response_target: f)
        end
      else
        FileUtils.cp(
          a.public_send(attachment_name).path,
          File.join(dir, a.public_send(attachment_name).original_filename)
        )
      end
    end
  end

  def team(team)
    if team.tiny_mce_assets.present?
      @tiny_mce_assets_to_copy.push(team.tiny_mce_assets)
    end
    {
      team: team,
      default_admin_id: team.user_teams.where(role: 2).first.user.id,
      users: team.users.map { |u| user(u) },
      user_teams: team.user_teams,
      notifications: Notification
        .includes(:user_notifications)
        .where('user_notifications.user_id': team.users)
        .map { |n| notification(n) },
      custom_fields: team.custom_fields,
      repositories: team.repositories.map { |r| repository(r) },
      tiny_mce_assets: team.tiny_mce_assets,
      protocols: team.protocols.where(my_module: nil).map { |pr| protocol(pr) },
      protocol_keywords: team.protocol_keywords,
      projects: team.projects.map { |p| project(p) }
    }
  end

  def notification(notification)
    notification_json = notification.as_json
    notification_json['type_of'] = Extends::NOTIFICATIONS_TYPES
                                   .key(notification.read_attribute('type_of'))
                                   .to_s
    notification_json
  end

  def user(user)
    user_json = user.as_json
    # Looks like Devise doesn't export some fields to JSON, so add it manually
    user_json['encrypted_password'] = user.encrypted_password
    user_json['confirmed_at'] = user.confirmed_at
    user_json['sign_in_count'] = user.sign_in_count
    user_json['last_sign_in_at'] = user.last_sign_in_at
    user_json['last_sign_in_ip'] = user.last_sign_in_ip
    copy_files([user], :avatar, File.join(@dir_to_export, 'avatars'))
    {
      user: user_json,
      user_notifications: user.user_notifications,
      user_identities: user.user_identities,
      repository_table_states:
        user.repository_table_states.where(repository: @team.repositories)
    }
  end

  def project(project)
    {
      project: project,
      user_projects: project.user_projects,
      activities: project.activities,
      project_comments: project.project_comments,
      reports: project.reports.map { |r| report(r) },
      experiments: project.experiments.map { |e| experiment(e) },
      tags: project.tags
    }
  end

  def report(report)
    {
      report: report,
      report_elements: report.report_elements
    }
  end

  def experiment(experiment)
    {
      experiment: experiment,
      my_modules:  experiment.my_modules.map { |m| my_module(m) },
      my_module_groups: experiment.my_module_groups
    }
  end

  def my_module(my_module)
    {
      my_module: my_module,
      outputs: my_module.outputs,
      my_module_tags: my_module.my_module_tags,
      task_comments: my_module.task_comments,
      my_module_repository_rows: my_module.my_module_repository_rows,
      user_my_modules: my_module.user_my_modules,
      protocols: my_module.protocols.map { |pr| protocol(pr) },
      results: my_module.results.map { |res| result(res) }
    }
  end

  def protocol(protocol)
    {
      protocol: protocol,
      protocol_protocol_keywords: protocol.protocol_protocol_keywords,
      steps: protocol.steps.map { |s| step(s) }
    }
  end

  def step(step)
    @assets_to_copy.push(step.assets.to_a) if step.assets.present?
    {
      step: step,
      checklists: step.checklists.map { |c| checklist(c) },
      step_comments: step.step_comments,
      step_assets: step.step_assets,
      assets: step.assets,
      step_tables: step.step_tables,
      tables: step.tables.map { |t| table(t) }
    }
  end

  def checklist(checklist)
    {
      checklist: checklist,
      checklist_items: checklist.checklist_items
    }
  end

  def table(table)
    return {} if table.nil?
    table_json = table.as_json(except: %i(contents data_vector))
    table_json['contents'] = Base64.encode64(table.contents)
    table_json['data_vector'] = Base64.encode64(table.data_vector)
    table_json
  end

  def result(result)
    @assets_to_copy.push(result.asset) if result.asset.present?
    {
      result: result,
      result_comments: result.result_comments,
      asset: result.asset,
      table: table(result.table),
      result_text: result.result_text
    }
  end

  def repository(repository)
    {
      repository: repository,
      repository_columns: repository.repository_columns.map do |c|
        repository_column(c)
      end,
      repository_rows: repository.repository_rows.map do |r|
        repository_row(r)
      end
    }
  end

  def repository_row(repository_row)
    {
      repository_row: repository_row,
      my_module_repository_rows: repository_row.my_module_repository_rows,
      repository_cells: repository_row.repository_cells.map do |c|
        repository_cell(c)
      end
    }
  end

  def repository_cell(cell)
    {
      repository_cell: cell,
      repository_value: cell.value,
      repository_value_asset: get_cell_value_asset(cell)
    }
  end

  def repository_column(column)
    {
      repository_column: column,
      repository_list_items: column.repository_list_items
    }
  end

  def get_cell_value_asset(cell)
    return unless cell.value_type == 'RepositoryAssetValue'
    @assets_to_copy.push(cell.value.asset)
    cell.value.asset
  end
end
