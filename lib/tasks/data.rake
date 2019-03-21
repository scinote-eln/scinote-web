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
          # Destroy user_team, and possibly team
          if user.teams.count > 0
            oids = user.teams.pluck(:id)
            oids.each do |oid|
              team = Team.find(oid)
              user_team = user.user_teams.where(team: team).first
              destroy_team = (team.users.count == 1 && team.created_by == user)
              if !user_team.destroy(nil) then
                raise Exception
              end
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

  desc 'Create demo project on existing users'
  task :create_demo_project_on_existing_users,
       %i(slice_size) => [:environment] do |_, args|
    args.with_defaults(slice_size: 800)

    require "#{Rails.root}/app/utilities/first_time_data_generator"
    include FirstTimeDataGenerator

    Rails.logger.info('Creating demo project on existing users')

    Team.all.order(updated_at: :desc)
        .each_slice(args[:slice_size]).with_index do |teams, i|
      Rails.logger.info("Processing slice with index #{i}. " \
                        "First team: #{teams.first.id}, " \
                        "Last team: #{teams.last.id}.")

      teams.each do |team|
        owner_ut = team.user_teams.where(role: 2).first
        next unless owner_ut

        FirstTimeDataGenerator.delay(
          run_at: i.hours.from_now,
          queue: :new_demo_project,
          priority: 10
        ).seed_demo_data_with_id(owner_ut.user.id, team.id)
      end
    end
  end
end
