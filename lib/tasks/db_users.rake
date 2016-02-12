require "#{Rails.root}/app/utilities/users_generator"
include UsersGenerator

namespace :db do

  desc "Load users into database from the provided YAML file"
  task :load_users, [ :file_path, :create_orgs ] => :environment do |task, args|
    if args.blank? or args.empty? or args[:file_path].blank?
      puts "No file provided"
      return
    end

    create_orgs = false
    if args[:create_orgs].present? and args[:create_orgs].downcase == "true"
      create_orgs = true
    end

    # Parse file
    yaml = YAML.load(File.read("#{args[:file_path]}"))

    begin
      ActiveRecord::Base.transaction do
        # Parse user & organization hashes from YAML
        orgs = yaml.select{ |k, v| /org_[0-9]+/ =~ k }
        users = yaml.select{ |k, v| /user_[0-9]+/ =~ k }

        # Create organizations
        orgs.each do |k, org_hash|
          org = Organization.order(created_at: :desc).where(name: org_hash["name"]).first
          if org.blank?
            org = Organization.create({
              name: org_hash["name"][0..99]
            })
          end
          org_hash["id"] = org.id
        end

        # Create users
        puts "Created users"
        users.each do |k, user_hash|
          password = user_hash["password"]
          if password.blank?
            password = generate_user_password
          end

          user_orgs = user_hash["organizations"]
          if user_orgs.blank?
            user_orgs = ""
          end

          org_ids =
            user_orgs
            .split(",")
            .collect{ |o| o.strip }
            .uniq
            .select{ |o| orgs.include? o }
            .collect{ |o| orgs[o]["id"] }

          user = create_user(
            user_hash["full_name"],
            user_hash["email"],
            password,
            true,
            create_orgs ? DEFAULT_PRIVATE_ORG_NAME : nil,
            org_ids
          )

          if user.id.present? then
            puts ""
            print_user(user, password)
          end
        end

        puts ""
      end
    rescue ActiveRecord::ActiveRecordError, ArgumentError
      puts "Error creating all users, transaction reverted"
    end
  end

  desc "Add a single user to the database"
  task :add_user => :environment do
    puts "Type in user's full name (e.g. 'Steve Johnson')"
    full_name = $stdin.gets.to_s.strip
    puts "Type in user's email (e.g. 'steve.johnson@gmail.com')"
    email = $stdin.gets.to_s.strip
    puts "Type in user's password (e.g. 'password'), or leave blank to let Rails generate password"
    password = $stdin.gets.to_s.strip
    if password.empty?
      password = generate_user_password
    end
    puts "Do you want Rails to create default user's organization? (T/F)"
    create_org = $stdin.gets.to_s.strip == "T"
    puts "Type names of any additional organizations you want the user to be admin of (delimited with ','), or leave blank"
    org_names = $stdin.gets.to_s.strip
    if org_names.empty?
      org_names = []
    else
      org_names = org_names.split(",").collect { |n| n.strip }
    end

    begin
      ActiveRecord::Base.transaction do
        # Add/fetch organizations if needed
        org_ids = []
        org_names.each do |org_name|
          org = Organization.order(created_at: :desc).where(name: org_name).first
          if org.blank? then
            org = Organization.create({ name: org_name[0..99] })
          end

          org_ids << org.id
        end

        user = create_user(
          full_name,
          email,
          password,
          true,
          create_org ? DEFAULT_PRIVATE_ORG_NAME : nil,
          org_ids
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
    rescue ActiveRecord::ActiveRecordError, ArgumentError, ActiveRecord::RecordNotSaved
      puts "Error creating user, transaction reverted"
    end
  end
end