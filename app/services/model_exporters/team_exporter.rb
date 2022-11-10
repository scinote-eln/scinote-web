# frozen_string_literal: true

module ModelExporters
  class TeamExporter < ModelExporter
    def initialize(team_id)
      super()
      @team = Team.find(team_id)
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

    def team(team)
      @tiny_mce_assets_to_copy.push(team.tiny_mce_assets) if team.tiny_mce_assets.present?
      {
        team: team,
        default_admin_id: team.user_assignments.where(user_role: UserRole.find_predefined_owner_role).first.user.id,
        users: team.users.map { |u| user(u) },
        user_assignments: team.user_assignments.map do |ua|
          user_assignment(ua)
        end,
        notifications: Notification
          .includes(:user_notifications)
          .where('user_notifications.user_id': team.users)
          .map { |n| notification(n) },
        repositories: team.repositories.map { |r| repository(r) },
        tiny_mce_assets: team.tiny_mce_assets.map { |tma| tiny_mce_asset_data(tma) },
        protocols: team.protocols.where(my_module: nil).map do |pr|
          protocol(pr).merge(
            user_assignments: pr.user_assignments.map do |ua|
              user_assignment(ua)
            end
          )
        end,
        protocol_keywords: team.protocol_keywords,
        project_folders: team.project_folders,
        projects: team.projects.map { |p| project(p) },
        activities: team.activities.where(project_id: nil),
        label_templates: label_templates(team.label_templates)
      }
    end

    def notification(notification)
      notification_json = notification.as_json
      notification_json['type_of'] = Extends::NOTIFICATIONS_TYPES
                                     .key(notification
                                          .read_attribute('type_of'))
                                     .to_s
      notification_json
    end

    def label_templates(templates)
      templates.where.not(type: 'FluicsLabelTemplate').map do |template|
        template_json = template.as_json
        template_json['type'] = template.type # as_json ignore 'type' column
        template_json
      end
    end

    def user(user)
      user_json = user.as_json
      # Looks like Devise doesn't export some fields to JSON, so add it manually
      user_json['encrypted_password'] = user.encrypted_password
      user_json['confirmed_at'] = user.confirmed_at
      user_json['sign_in_count'] = user.sign_in_count
      user_json['last_sign_in_at'] = user.last_sign_in_at
      user_json['last_sign_in_ip'] = user.last_sign_in_ip
      user_json['avatar'] = user.avatar.blob if user.avatar.attached?
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
      experiments = project.experiments.map do |e|
        experiment, assets = ExperimentExporter.new(e.id).experiment
        @assets_to_copy << assets
        experiment
      end

      {
        project: project,
        user_assignments: project.user_assignments.map do |ua|
          user_assignment(ua)
        end,
        user_projects: project.user_projects,
        activities: project.activities,
        project_comments: project.project_comments,
        reports: project.reports.map { |r| report(r) },
        experiments: experiments,
        tags: project.tags
      }
    end

    def user_assignment(user_assignment)
      {
        user_id: user_assignment.user_id,
        assigned_by_id: user_assignment.assigned_by_id,
        role_name: user_assignment.user_role.name,
        assigned: user_assignment.assigned,
        team_id: user_assignment.team_id
      }
    end

    def report(report)
      {
        report: report,
        user_assignments: report.user_assignments.map do |ua|
          user_assignment(ua)
        end,
        report_elements: report.report_elements
      }
    end

    def repository(repository)
      result = {
        repository: repository,
        repository_columns: repository.repository_columns.map do |c|
          repository_column(c)
        end,
        repository_rows: repository.repository_rows.map do |r|
          repository_row(r)
        end
      }
      unless repository.is_a?(RepositorySnapshot)
        result[:user_assignments] =
          repository.user_assignments.where(team: repository.team, user: repository.team.users).map do |ua|
            user_assignment(ua)
          end
        result[:repository_snapshots] = repository.repository_snapshots.map { |r| repository(r) }
      end
      result
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
        repository_value_asset: get_cell_value_asset(cell),
        repository_value_checklist: get_cell_value_checklist(cell)
      }
    end

    def repository_column(column)
      {
        repository_column: column,
        repository_list_items: column.repository_list_items,
        repository_checklist_items: column.repository_checklist_items,
        repository_status_items: column.repository_status_items
      }
    end

    def tiny_mce_asset_data(asset)
      {
        tiny_mce_asset: asset,
        tiny_mce_asset_blob: asset.image.blob
      }
    end

    def get_cell_value_asset(cell)
      return unless cell.value_type == 'RepositoryAssetValue'

      @assets_to_copy.push(cell.value.asset)
      {
        asset: cell.value.asset,
        asset_blob: cell.value.asset.blob
      }
    end

    def get_cell_value_checklist(cell)
      return unless cell.value_type == 'RepositoryChecklistValue'

      cell.value.repository_checklist_items_values
    end
  end
end
