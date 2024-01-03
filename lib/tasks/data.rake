# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

namespace :data do
  Rails.logger = Logger.new(STDOUT)

  desc "Remove expired temporary files"
  task clean_temp_files: :environment do
    Rails.logger.info "Cleaning temporary files older than 3 days"
    TempFile.where("created_at < ?", 3.days.ago).each do |tmp_file|
      TempFile.transaction do
        begin
          tmp_file.destroy!
        rescue Exception => e
          Rails.logger.error "Failed to destroy temporary file #{tmp_file.id}: #{e}"
          raise ActiveRecord::Rollback
        else
          Rails.logger.info "Temporary file ##{tmp_file.id} removed"
        end
      end
    end
  end

  def destroy_users(users)
    users.each do |user|

      User.transaction do
        begin
          # Destroy user team assignments, and possibly team
          if user.teams.count > 0
            oids = user.teams.pluck(:id)
            oids.each do |oid|
              team = Team.find(oid)
              team_assignment = user.user_assignments.where(assignable: team).take
              destroy_team = (team.users.count == 1 && team.created_by == user)
              team_assignment.destroy!
              team.destroy! if destroy_team
            end
          end

          user.destroy!
        rescue Exception => e
          Rails.logger.error "Failed to destroy unconfirmed user #{user.id}: #{e}"
          raise ActiveRecord::Rollback
        else
          Rails.logger.info "Unconfirmed user ##{user.id} removed"
        end
      end
    end
  end

  desc "Remove unconfirmed user accounts"
  task clean_unconfirmed_users: :environment do
    Rails.logger.info "Cleaning unconfirmed users"

    # First, remove the users who signed up by themselves
    users = User
    .where(confirmed_at: nil)
    .where.not(confirmation_token: nil)
    .where(invitation_token: nil)
    .where("created_at < ?", Devise.confirm_within.ago)
    destroy_users(users)

    # Now, remove users who were invited
    users = User
    .where(confirmed_at: nil)
    .where(invitation_accepted_at: nil)
    .where(confirmation_token: nil)
    .where.not(invitation_token: nil)
    .where("created_at < ?", Devise.invite_for.ago)
    destroy_users(users)

    # Remove users who didn't finish signup with LinkedIn
    users = User.joins(:user_identities)
                .where(confirmed_at: nil)
                .where('users.created_at < ?', Devise.confirm_within.ago)
    destroy_users(users)
  end

  desc "Remove temporary and obsolete data"
  task clean: [:environment, :clean_temp_files, :clean_unconfirmed_users]

  desc 'Export team to directory'
  task :team_export, [:team_id] => [:environment] do |_, args|
    Rails.logger.info(
      "Exporting team with ID:#{args[:team_id]} to directory in tmp"
    )
    te = ModelExporters::TeamExporter.new(args[:team_id])
    te&.export_to_dir
  end

  desc 'Import team from directory'
  task :team_import, [:dir_path] => [:environment] do |_, args|
    Rails.logger.info(
      "Importing team from directory #{args[:dir_path]}"
    )
    TeamImporter.new.import_from_dir(args[:dir_path])
  end

  desc 'Delete team and all data inside the team'
  task :team_delete, [:team_id] => [:environment] do |_, args|
    Rails.logger.info(
      "Deleting team with ID:#{args[:team_id]} and all data inside the team"
    )
    team = Team.find_by_id(args[:team_id])
    raise StandardError, 'Can not load team' unless team

    UserDataDeletion.delete_team_data(team) if team
  end

  desc 'Export experiment to directory'
  task :experiment_template_export,
       [:experiment_id] => [:environment] do |_, args|
    Rails.logger.info(
      "Exporting experiment template with ID:#{args[:experiment_id]} "\
      "to directory in tmp"
    )
    ee = ModelExporters::ExperimentExporter.new(args[:experiment_id])
    ee&.export_template_to_dir
  end

  desc 'Import experiment from directory to given project'
  task :experiment_template_import,
       %i(dir_path project_id user_id) => [:environment] do |_, args|
    Rails.logger.info(
      "Importing experiment from directory #{args[:dir_path]}"
    )
    TeamImporter.new.import_experiment_template_from_dir(args[:dir_path],
                                                         args[:project_id],
                                                         args[:user_id])
  end

  desc 'Update all templates projects'
  task :update_all_templates,
       %i(slice_size) => [:environment] do |_, args|
    args.with_defaults(slice_size: 800)

    Rails.logger.info('Templates, syncing all templates projects')
    Team.all.order(updated_at: :desc)
        .each_slice(args[:slice_size].to_i).with_index do |teams, i|
      Rails.logger.info("Processing slice with index #{i}. " \
                        "First team: #{teams.first.id}, " \
                        "Last team: #{teams.last.id}.")

      teams.each do |team|
        TemplatesService.new.delay(
          run_at: i.hours.from_now,
          queue: :templates,
          priority: 5
        ).update_team(team)
      end
    end
  end

  desc 'Purge all experiment workflow images'
  task purge_experiment_workflow_images: :environment do
    ActiveStorage::Attachment.where(name: 'workflowimg').delete_all
  end

  desc 'Purge all experiment workflow images'
  task cleanup_blobs: :environment do
    ActiveStorage::Blob.unattached.find_each(&:purge_later)
  end

  desc 'Reset to defaults all predefined user roles'
  task reset_predefined_user_roles: :environment do
    ActiveRecord::Base.transaction do
      %i(owner_role normal_user_role technician_role viewer_role).each do |predefined_role|
        reference_role = UserRole.public_send(predefined_role)
        existing_role = UserRole.find_by(name: reference_role.name)
        if existing_role.present?
          # rubocop:disable Rails/SkipsModelValidations
          existing_role.update_attribute(:permissions, reference_role.permissions)
          # rubocop:enable Rails/SkipsModelValidations
        else
          reference_role.save!
        end
      end
    end
  end

  desc 'Reset repositories user assignments'
  task reset_repositories_user_assignments: :environment do
    ActiveRecord::Base.transaction do
      Team.all.find_each do |team|
        team.user_assignments.find_each do |team_user_assignment|
          team.repositories.find_each do |repository|
            new_user_assignment =
              repository.automatic_user_assignments.find_or_initialize_by(user: team_user_assignment.user, team: team)
            new_user_assignment.user_role = team_user_assignment.user_role
            new_user_assignment.assigned_by = team_user_assignment.assigned_by
            new_user_assignment.assigned = :automatically
            new_user_assignment.save!
          end
        end
      end
    end
  end

  desc 'Reset protocols creator user assignments'
  task reset_protocols_creator_user_assignments: :environment do
    ActiveRecord::Base.transaction do
      owner_role = UserRole.find_predefined_owner_role
      protocols =
        Protocol.where(protocol_type: Protocol::REPOSITORY_TYPES)
                .joins('LEFT OUTER JOIN "user_assignments" ON "user_assignments"."assignable_type" = \'Protocol\' ' \
                       'AND "user_assignments"."assignable_id" = "protocols"."id" ' \
                       'AND "user_assignments"."assigned" = 1 ' \
                       'AND "user_assignments"."user_id" = "protocols"."added_by_id"')
                .where('"user_assignments"."id" IS NULL')
                .distinct
      protocols.find_each do |protocol|
        new_user_assignment = protocol.user_assignments
                                      .find_or_initialize_by(user: protocol.added_by, team: protocol.team)
        new_user_assignment.user_role = owner_role
        new_user_assignment.assigned_by = protocol.added_by
        new_user_assignment.assigned = :manually
        new_user_assignment.save!
      end
    end
  end

  desc 'Extract missing asset texts'
  task extract_missing_asset_texts: :environment do
    Asset.joins(:file_blob)
         .where.missing(:asset_text_datum)
         .where(file_blob: { content_type: Constants::TEXT_EXTRACT_FILE_TYPES })
         .find_each(&:extract_asset_text)
  end
end

# rubocop:enable Metrics/BlockLength
