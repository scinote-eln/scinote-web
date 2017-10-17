require "#{Rails.root}/app/utilities/users_generator"
include UsersGenerator

namespace :db do

  desc "Load users into database from the provided YAML file"
  task :load_users, [ :file_path, :create_teams ] => :environment do |task, args|
    if args.blank? or args.empty? or args[:file_path].blank?
      puts "No file provided"
      return
    end

    create_teams = false
    if args[:create_teams].present? and args[:create_teams].downcase == "true"
      create_teams = true
    end

    # Parse file
    yaml = YAML.load(File.read("#{args[:file_path]}"))

    begin
      ActiveRecord::Base.transaction do
        # Parse user & team hashes from YAML
        teams = yaml.select { |k, v| /team_[0-9]+/ =~ k }
        users = yaml.select { |k, v| /user_[0-9]+/ =~ k }

        # Create teams
        teams.each do |k, team_hash|
          team = Team.order(created_at: :desc)
                     .where(name: team_hash['name'])
                     .first
          team = Team.create(name: team_hash['name'][0..99]) if team.blank?
          team_hash['id'] = team.id
        end

        # Create users
        puts 'Created users'
        users.each do |k, user_hash|
          password = user_hash['password']
          password = generate_user_password if password.blank?

          user_teams = user_hash['teams']
          user_teams = '' if user_teams.blank?

          team_ids =
            user_teams
            .split(',')
            .collect(&:strip)
            .uniq
            .select { |o| teams.include? o }
            .collect { |o| teams[o]['id'] }

          user = create_user(
            user_hash['full_name'],
            user_hash['email'],
            password,
            true,
            create_teams ? Constants::DEFAULT_PRIVATE_TEAM_NAME : nil,
            team_ids
          )

          if user.id.present?
            puts ''
            print_user(user, password)
          end
        end

        puts ''
      end
    rescue ActiveRecord::ActiveRecordError, ArgumentError
      puts 'Error creating all users, transaction reverted'
    end
  end

  desc 'Add a single user to the database'
  task :add_user => :environment do
    puts 'Type in user\'s full name (e.g. \'Steve Johnson\')'
    full_name = $stdin.gets.to_s.strip
    puts 'Type in user\'s email (e.g. \'steve.johnson@gmail.com\')'
    email = $stdin.gets.to_s.strip
    puts 'Type in user\'s password (e.g. \'password\'), or ' \
         'leave blank to let Rails generate password'
    password = $stdin.gets.to_s.strip
    if password.empty?
      password = generate_user_password
    end
    puts 'Do you want Rails to create default user\'s team? (T/F)'
    create_team = $stdin.gets.to_s.strip == 'T'
    puts 'Type names of any additional teams you want the user ' \
         'to be admin of (delimited with \',\'), or leave blank'
    team_names = $stdin.gets.to_s.strip
    if team_names.empty?
      team_names = []
    else
      team_names = team_names.split(',').collect(&:strip)
    end

    begin
      ActiveRecord::Base.transaction do
        # Add/fetch teams if needed
        team_ids = []
        team_names.each do |team_name|
          team = Team.order(created_at: :desc).where(name: team_name).first
          team = Team.create(name: team_name[0..99]) if team.blank?

          team_ids << team.id
        end

        user = create_user(
          full_name,
          email,
          password,
          true,
          create_team ? Constants::DEFAULT_PRIVATE_TEAM_NAME : nil,
          team_ids
        )

        if user.id.present? then
          puts "Successfully created user"
          puts ""
          print_user(user, password)
        else
          puts "Error creating new user"
        end

        puts ""
      end
    rescue ActiveRecord::ActiveRecordError, ArgumentError, ActiveRecord::RecordNotSaved => e
      puts "Error creating user, transaction reverted: #{$!}"
    end
  end
end
