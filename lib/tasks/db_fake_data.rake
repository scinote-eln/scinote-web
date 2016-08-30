require "#{Rails.root}/app/utilities/users_generator"
require "#{Rails.root}/app/utilities/renaming_util"
require "#{Rails.root}/test/helpers/fake_test_helper"
include UsersGenerator
include RenamingUtil
include FakeTestHelper

namespace :db do

  NR_ORGANIZATIONS = 4
  NR_USERS = 100
  NR_SAMPLE_TYPES = 20
  NR_SAMPLE_GROUPS = 20
  NR_CUSTOM_FIELDS = 20
  NR_SAMPLES = 100
  NR_PROTOCOLS = 20
  NR_PROTOCOL_KEYWORDS = 20
  NR_PROJECTS = 3
  NR_EXPERIMENTS = 4
  NR_MODULE_GROUPS = 4
  NR_MODULES = 4
  NR_STEPS = 3
  NR_RESULTS = 4
  NR_REPORTS = 4
  NR_COMMENTS = 10
  RATIO_USER_ORGANIZATIONS = 0.5
  NR_MAX_USER_ORGANIZATIONS = 20
  RATIO_CUSTOM_FIELDS = 0.7
  RATIO_SAMPLE_CUSTOM_FIELDS = 0.6
  RATIO_PROTOCOL_KEYWORDS = 0.3
  THRESHOLD_PROTOCOL_IN_MODULE_LINKED = 0.5
  THRESHOLD_PROTOCOL_PUBLIC = 0.6
  THRESHOLD_PROTOCOL_ARCHIVED = 0.2
  NR_MAX_USER_PROJECTS = 15
  RATIO_USER_PROJECTS = 0.5
  RATIO_COMMENTS = 0.7
  NR_MAX_USER_MODULES = 15
  RATIO_USER_MODULES = 0.5
  NR_MAX_SAMPLE_MODULES = 10
  RATIO_SAMPLE_MODULES = 0.7
  RATIO_MODULE_MODULE_GROUPS = 0.8
  RATIO_EDGES = 0.7
  RATIO_STEP_COMPLETED = 0.5
  NR_MAX_STEP_ATTACHMENTS = 2
  RATIO_STEP_ATTACHMENTS = 0.2
  NR_MAX_CHECKLIST_ITEMS = 20
  RATIO_CHECKLIST_ITEM = 0.2
  RATIO_CHECKLIST_ITEM_CHECKED = 0.5
  RATIO_RESULT_ARCHIVED = 0.2
  RATIO_REPORT_ELEMENTS = 0.75

  THRESHOLD_ARCHIVED = 0.2
  THRESHOLD_RESTORED = 0.9

  MIN_FILE_SIZE = 0.01
  MAX_FILE_SIZE = 0.1

  desc "Drops the database, sets it up and inserts fake data for " +
       "the current RAILS_ENV. WARNING: THIS WILL ERASE ALL " +
       "CURRENT DATA IN THE DATABASE."
  task :fake => :environment do
    Rake::Task["db:drop"].reenable
    Rake::Task["db:drop"].invoke
    Rake::Task["db:setup"].reenable
    Rake::Task["db:setup"].invoke
    Rake::Task["db:fake:generate"].reenable
    Rake::Task["db:fake:generate"].invoke
  end

  namespace :fake do
    desc "Generates fake data & inserts it into database for the " +
         "current RAILS_ENV."
    task :generate => :environment do
      require 'rgl/base'
      require 'rgl/adjacency'
      require 'rgl/topsort'

      puts "Verbose? (Y/n)"
      res = $stdin.gets.to_s.downcase.strip
      unless res.in?(["", "y", "n"]) then
        puts "Invalid parameter, exiting"
        return
      end
      verbose = res.in?(["", "y"])

      puts "Simple seeding? (Y/n)"
      res = $stdin.gets.to_s.downcase.strip
      unless res.in?(["", "y", "n"]) then
        puts "Invalid parameter, exiting"
        return
      end
      simple = res.in?(["", "y"])

      if simple
        puts "Choose the size of generated dataset(T - tiny, " +
             "s - small, m - medium, l - large, h -huge)"
        res = $stdin.gets.to_s.downcase.strip
        unless res.in?(["", "t", "s", "m", "l", "h"]) then
          puts "Invalid parameter, exiting"
          return
        end

        case res
          when "", "t"
            factor = 0.5
          when "s"
            factor = 1
          when "m"
            factor = 5
          when "l"
            factor = 20
          when "h"
            factor = 100
        end

        nr_org = NR_ORGANIZATIONS * factor
        nr_users = NR_USERS * factor
        nr_sample_types = NR_SAMPLE_TYPES * factor
        nr_sample_groups = NR_SAMPLE_GROUPS * factor
        nr_custom_fields = NR_CUSTOM_FIELDS * factor
        nr_samples = NR_SAMPLES * factor
        nr_protocols = NR_PROTOCOLS * factor
        nr_protocol_keywords = NR_PROTOCOL_KEYWORDS * factor
        nr_projects = NR_PROJECTS * factor
        nr_experiments = NR_EXPERIMENTS * factor
        nr_module_groups = NR_MODULE_GROUPS * factor
        nr_modules = NR_MODULES * factor
        nr_steps = NR_STEPS * factor
        nr_results = NR_RESULTS * factor
        nr_reports = NR_REPORTS * factor
        nr_comments = NR_COMMENTS * factor
      else
        puts "Type in the number of seeded organizations"
        nr_org = $stdin.gets.to_i
        puts "Type in the number of seeded users"
        nr_users = $stdin.gets.to_i
        puts "Type in the number of seeded sample types " +
             "for each organization"
        nr_sample_types = $stdin.gets.to_i
        puts "Type in the number of seeded sample groups for " +
             "each organization"
        nr_sample_groups = $stdin.gets.to_i
        puts "Type in the max. number of seeded custom fields " +
             "for each organization"
        nr_custom_fields = $stdin.gets.to_i
        puts "Type in the number of seeded samples for each organization"
        nr_samples = $stdin.gets.to_i
        puts "Type in the number of seeded protocols for each organization"
        nr_protocols = $stdin.gets.to_i
        puts "Type in the number of seeded protocol keywords for each organization"
        nr_protocol_keywords = $stdin.gets.to_i
        puts "Type in the number of seeded projects for each organization"
        nr_projects = $stdin.gets.to_i
        puts "Type in the number of seeded experiments for each project"
        nr_experiments = $stdin.gets.to_i
        puts "Type in the number of seeded workflows for each experiment"
        nr_module_groups = $stdin.gets.to_i
        puts "Type in the number of seeded modules for each experiment"
        nr_modules = $stdin.gets.to_i
        puts "Type in the number of seeded steps for each module"
        nr_steps = $stdin.gets.to_i
        puts "Type in the number of seeded results for each module"
        nr_results = $stdin.gets.to_i
        puts "Type in the number of seeded reports for each project"
        nr_reports = $stdin.gets.to_i
        puts "Type in the max. number of seeded comments for each " +
             "commentable item"
        nr_comments = $stdin.gets.to_i
      end

      begin
        ActiveRecord::Base.transaction do

          puts "Generating fake organizations..."
          taken_org_names = []
          for _ in 1..nr_org
            begin
              name = Faker::University.name
            end while name.in? taken_org_names
            taken_org_names << name

            Organization.create(
              name: name,
              description: rand >= 0.7 ? Faker::Lorem.sentence : nil
            )
          end

          all_organizations = Organization.all

          puts "Generating fake users..."
          taken_emails = []
          for _ in 1..nr_users
            begin
              if rand >= 0.8
                name = generate_got_name
              else
                name = Faker::Name.name
              end
              email_name = name.downcase.remove(".").split(" ").join(".")
              password = Faker::Internet.password(10, 20)
              email = Faker::Internet.free_email(email_name)
            end while email.in? taken_emails
            taken_emails << email

            user = create_user(
              name,
              email,
              password,
              true,
              nil,
              []
            )
            user.update(
              confirmed_at: Faker::Date.backward(30),
            )
            if verbose then
              puts "  Generated user #{name} (email: #{email}, " +
                   "password: #{password})"
            end

            # Randomly assign user to organizations
            taken_org_ids = []
            for _ in 1..[NR_MAX_USER_ORGANIZATIONS, all_organizations.count].min
              if rand <= RATIO_USER_ORGANIZATIONS then
                begin
                  org = pluck_random(all_organizations)
                end while org.id.in? taken_org_ids
                taken_org_ids << org.id

                UserOrganization.create(
                  user: user,
                  organization: org,
                  role: rand(0..2)
                )
              end
            end
          end

          puts "Generating fake sample types..."
          all_organizations.find_each do |org|
            for _ in 1..nr_sample_types
              SampleType.create(
                name: Faker::Commerce.department(4),
                organization: org
              )
            end
          end

          puts "Generating fake sample groups..."
          all_organizations.find_each do |org|
            for _ in 1..nr_sample_groups
              SampleGroup.create(
                name: Faker::Commerce.color,
                organization: org,
                color: generate_color
              )
            end
          end

          puts "Generating fake custom fields..."
          all_organizations.find_each do |org|
            for _ in 1..nr_custom_fields
              if rand <= RATIO_CUSTOM_FIELDS then
                CustomField.create(
                  name: Faker::Team.state,
                  organization: org,
                  user: pluck_random(org.users)
                )
              end
            end
          end

          puts "Generating fake samples..."
          all_organizations.find_each do |org|
            for _ in 1..nr_samples
              sample = Sample.create(
                name: Faker::Book.title,
                organization: org,
                user: pluck_random(org.users),
                sample_type: pluck_random(org.sample_types),
                sample_group: pluck_random(org.sample_groups)
              )

              # Add some custom fields to sample
              org.custom_fields.find_each do |cf|
                if rand <= RATIO_SAMPLE_CUSTOM_FIELDS then
                  SampleCustomField.create(
                    sample: sample,
                    custom_field: cf,
                    value: Faker::Team.state
                  )
                end
              end
            end
          end

          puts "Generating fake protocol keywords"
          all_organizations.find_each do |org|
            taken_kw_names = []
            for _ in 1..nr_protocol_keywords
              begin
                name = Faker::Book.genre
              end while name.in? taken_kw_names
              taken_kw_names << name
              ProtocolKeyword.create(
                organization: org,
                name: name
              )
            end
          end

          puts "Generating fake repository protocols..."
          all_organizations.find_each do |org|
            for _ in 1..nr_protocols
              protocol = generate_fake_protocol(org, nil, nr_steps, nr_comments)

              if verbose then
                puts "    Generated protocol #{protocol.name}"
              end
            end
          end

          puts "Generating fake projects..."
          all_organizations.find_each do |org|
            taken_project_names = []
            for _ in 1..nr_projects
              begin
                name = Faker::Company.name[0..29]
              end while name.in? taken_project_names
              taken_project_names << name

              author = pluck_random(org.users)
              created_at = Faker::Time.backward(500)
              last_modified_by = pluck_random(org.users)
              archived_by = pluck_random(org.users)
              archived_on = Faker::Time.between(created_at, DateTime.now)
              restored_by = pluck_random(org.users)
              restored_on = Faker::Time.between(archived_on, DateTime.now)
              status = random_status

              project = Project.create(
                visibility: rand(0..1),
                name: name,
                due_date: nil,
                organization: org,
                created_by: author,
                created_at: created_at,
                last_modified_by: last_modified_by,
                archived: status == :archived,
                archived_by: status.in?([:archived, :restored]) ?
                  archived_by : nil,
                archived_on: status.in?([:archived, :restored]) ?
                  archived_on : nil,
                restored_by: status == :restored ? restored_by : nil,
                restored_on: status == :restored ? restored_on : nil
              )
              # Automatically assign project author onto project
              UserProject.create(
                user: author,
                project: project,
                role: 0,
                created_at: created_at
              )

              # Activities
              Activity.create(
                type_of: :create_project,
                user: author,
                project: project,
                message: I18n.t(
                  "activities.create_project",
                  user: author.full_name,
                  project: project.name
                ),
                created_at: created_at
              )
              if status.in?([:archived, :restored]) then
                Activity.create(
                  type_of: :archive_project,
                  user: archived_by,
                  project: project,
                  message: I18n.t(
                    "activities.archive_project",
                    user: archived_by.full_name,
                    project: project.name
                  ),
                  created_at: archived_on
                )
              end
              if status == :restored then
                Activity.create(
                  type_of: :restore_project,
                  user: restored_by,
                  project: project,
                  message: I18n.t(
                    "activities.restore_project",
                    user: restored_by.full_name,
                    project: project.name
                  ),
                  created_at: restored_on
                )
              end

              # Assign users onto the project
              taken_user_ids = []
              for _ in 2..[NR_MAX_USER_PROJECTS, org.users.count].min
                if rand <= RATIO_USER_PROJECTS
                  begin
                    user = pluck_random(org.users)
                  end while user.id.in? taken_user_ids
                  taken_user_ids << user.id

                  assigned_on = Faker::Time.backward(500)
                  assigned_by = pluck_random(project.users)
                  up = UserProject.create(
                    user: user,
                    project: project,
                    role: rand(0..3),
                    created_at: assigned_on,
                    assigned_by: assigned_by
                  )
                  Activity.create(
                    type_of: :assign_user_to_project,
                    user: assigned_by,
                    project: project,
                    message: I18n.t(
                      "activities.assign_user_to_project",
                      assigned_user: user.full_name,
                      role: up.role_str,
                      project: project.name,
                      assigned_by_user: assigned_by.full_name
                    ),
                    created_at: assigned_on
                  )
                end
              end

              # Add some comments
              for _ in 1..nr_comments
                generate_fake_project_comment(project) if rand <= RATIO_COMMENTS
              end
            end
          end

          puts "Generating fake experiments..."
          Project.find_each do |project|
            for _ in 1..nr_experiments
              status = random_status
              created_at = Faker::Time.backward(500)
              archived_by = pluck_random(project.users)
              archived_on = Faker::Time.between(created_at, DateTime.now)
              restored_by = pluck_random(project.users)
              restored_on = Faker::Time.between(archived_on, DateTime.now)

              author = pluck_random(project.users)
              Experiment.create(
                name: Faker::Hacker.noun,
                description: Faker::Hipster.sentence,
                project: project,
                created_at: created_at,
                created_by: author,
                last_modified_by: author,
                archived: status.in?([:active, :restored]),
                archived_on: status.in?([:archived, :restored]) ?
                  archived_on : nil,
                archived_by: status.in?([:archived, :restored]) ?
                  archived_by : nil,
                restored_on: status == :restored ? restored_on : nil,
                restored_by: status == :restored ? restored_by : nil
              )
            end
          end

          puts "Generating fake workflows..."
          Experiment.find_each do |experiment|
            for _ in 1..nr_module_groups
              MyModuleGroup.create(
                name: Faker::Hacker.noun,
                experiment: experiment
              )
            end
          end

          puts "Generating fake modules..."
          total_experiment = Experiment.count
          Experiment.find_each.with_index do |experiment, i|
            if verbose then
              puts "  Generating modules for experiment #{experiment.name} " +
                   "(#{i + 1} of #{total_experiment})..."
            end
            project = experiment.project
            taken_pos = []
            for _ in 1..nr_modules
              begin
                x = rand(0..nr_modules) * 32
                y = rand(0..nr_modules) * 16
              end while [x, y].in? taken_pos
              taken_pos << [x, y]

              status = random_status
              author = pluck_random(org.users)
              created_at = Faker::Time.backward(500)
              archived_by = pluck_random(org.users)
              archived_on = Faker::Time.between(created_at, DateTime.now)
              restored_by = pluck_random(org.users)
              restored_on = Faker::Time.between(archived_on, DateTime.now)

              my_module = MyModule.create(
                name: Faker::Hacker.verb,
                created_by: author,
                created_at: created_at,
                due_date: rand <= 0.5 ?
                  Faker::Time.forward(500) : nil,
                description: rand <= 0.5 ?
                  Faker::Hacker.say_something_smart : nil,
                x: x,
                y: y,
                experiment: experiment,
                my_module_group: status == :archived ?
                  nil :
                  (rand <= RATIO_MODULE_MODULE_GROUPS ?
                    pluck_random(experiment.my_module_groups) : nil
                  ),
                archived: status == :archived,
                archived_on: status.in?([:archived, :restored]) ?
                  archived_on : nil,
                archived_by: status.in?([:archived, :restored]) ?
                  archived_by : nil,
                restored_on: status == :restored ? restored_on : nil,
                restored_by: status == :restored ? restored_by : nil
              )

              # Activities
              Activity.create(
                type_of: :create_module,
                user: author,
                project: my_module.experiment.project,
                my_module: my_module,
                message: I18n.t(
                  "activities.create_module",
                  user: author.full_name,
                  module: my_module.name
                ),
                created_at: created_at
              )
              if status.in?([:archived, :restored]) then
                Activity.create(
                  type_of: :archive_module,
                  user: archived_by,
                  project: my_module.experiment.project,
                  my_module: my_module,
                  message: I18n.t(
                    "activities.archive_module",
                    user: archived_by.full_name,
                    module: my_module.name
                  ),
                  created_at: archived_on
                )
              end
              if status == :restored then
                Activity.create(
                  type_of: :restore_module,
                  user: restored_by,
                  project: my_module.experiment.project,
                  my_module: my_module,
                  message: I18n.t(
                    "activities.restore_module",
                    user: restored_by.full_name,
                    module: my_module.name
                  ),
                  created_at: restored_on
                )
              end

              if verbose then
                puts "    Generated module #{my_module.name}"
              end

              # Assign some users onto module
              taken_user_ids = []
              for _ in 1..[NR_MAX_USER_MODULES, project.users.count].min
                if rand <= RATIO_USER_MODULES then
                  begin
                    user = pluck_random(project.users)
                  end while user.id.in? taken_user_ids
                  taken_user_ids << user.id

                  assigned_on = Faker::Time.backward(500)
                  assigned_by = pluck_random(my_module.experiment.project.users)
                  UserMyModule.create(
                    user: user,
                    my_module: my_module,
                    assigned_by: pluck_random(project.users),
                    created_at: assigned_on
                  )
                  Activity.create(
                    type_of: :assign_user_to_module,
                    user: assigned_by,
                    project: my_module.experiment.project,
                    my_module: my_module,
                    message: I18n.t(
                      "activities.assign_user_to_module",
                      assigned_user: user.full_name,
                      module: my_module.name,
                        assigned_by_user: assigned_by.full_name
                    ),
                    created_at: assigned_on
                  )
                end
              end

              # Assign some samples onto module
              taken_sample_ids = []
              for _ in 1..[
                NR_MAX_SAMPLE_MODULES,
                project.organization.samples.count
              ].min
                if rand <= RATIO_SAMPLE_MODULES then
                  begin
                    sample = pluck_random(project.organization.samples)
                  end while sample.id.in? taken_sample_ids
                  taken_sample_ids << sample.id

                  SampleMyModule.create(
                    sample: sample,
                    my_module: my_module
                  )
                end
              end

              # Add some comments
              for _ in 1..nr_comments
                generate_fake_module_comment(my_module) if rand <= RATIO_COMMENTS
              end
            end

            # Generate some connections between modules
            experiment.my_module_groups.find_each do |my_module_group|
              if my_module_group.my_modules.empty? or
                my_module_group.my_modules.count == 1
                # If any module group doesn't contain
                # any modules (or has only 1 module), remove it
                my_module_group.destroy
              else
                # Make connections between project modules,
                # keeping in mind not to generate cycles
                n = my_module_group.my_modules.count
                max_edges = (n - 1) * n / 2

                dg = RGL::DirectedAdjacencyGraph.new
                for _ in 1..max_edges
                  if rand <= RATIO_EDGES
                    begin
                      m1 = pluck_random(my_module_group.my_modules)
                      m2 = pluck_random(my_module_group.my_modules)
                    end while (
                      m1 == m2 or
                      dg.has_edge?(m1.id, m2.id)
                    )

                    # Only add edge if it won't make graph cyclic
                    dg.add_edge(m1.id, m2.id)
                    if dg.acyclic?
                      Connection.create(
                        input_id: m1.id,
                        output_id: m2.id
                      )
                    else
                      dg.remove_edge(m1.id, m2.id)
                    end
                  end
                end

                # Set order number for each module in group
                topsort = dg.topsort_iterator.to_a
                my_module_group.my_modules.each do |mm|
                  if topsort.include? mm.id
                    mm.workflow_order = topsort.find_index(mm.id)
                    mm.save!
                  end
                end
              end
            end
          end

          puts "Generating fake module protocols..."
          Experiment.find_each do |experiment|
            experiment.my_modules.find_each do |my_module|
              generate_fake_protocol(experiment.project.organization, my_module, nr_steps, nr_comments)
            end
          end

          puts "Generating fake module results..."
          Experiment.find_each do |experiment|
            experiment.my_modules.find_each do |my_module|
              for _ in 1..nr_results
                user = pluck_random(my_module.users)
                created_at = Faker::Time.backward(500)
                archived_on = Faker::Time.between(created_at, DateTime.now)
                restored_on = Faker::Time.between(archived_on, DateTime.now)
                status = random_status

                result = Result.new(
                  name: Faker::Hacker.abbreviation[0..49],
                  my_module: my_module,
                  user: user,
                  created_at: created_at,
                  archived: status == :archived,
                  archived_by: status.in?([:archived, :restored]) ?
                    user : nil,
                  archived_on: status.in?([:archived, :restored]) ?
                    archived_on : nil,
                  restored_by: status == :restored ? user : nil,
                  restored_on: status == :restored ? restored_on : nil
                )

                type = [:text, :asset, :table][rand(0..2)]
                case type
                  when :text
                    result.result_text = ResultText.new(
                      text: Faker::Hipster.paragraph,
                    )
                    str = "activities.add_text_result"
                    str2 = "activities.archive_text_result"
                  when :asset
                    result.asset = Asset.new(
                      file: generate_file(rand(MIN_FILE_SIZE..MAX_FILE_SIZE)),
                      created_by: result.user
                    )
                    str = "activities.add_asset_result"
                    str2 = "activities.archive_asset_result"
                  when :table
                    result.table = Table.new(
                      contents: generate_table_contents(rand(30), rand(150)),
                      created_by: result.user
                    )
                    str = "activities.add_table_result"
                    str2 = "activities.archive_table_result"
                end

                result.save

                # Add activities
                Activity.create(
                  type_of: :add_result,
                  project: experiment.project,
                  my_module: my_module,
                  user: user,
                  created_at: created_at,
                  message: I18n.t(
                    str,
                    user: user.full_name,
                    result: result.name
                  )
                )
                if status.in?([:archived, :restored]) then
                  Activity.create(
                    type_of: :archive_result,
                    user: user,
                    project: experiment.project,
                    my_module: my_module,
                    message: I18n.t(
                      str2,
                      user: user.full_name,
                      result: result.name
                    ),
                    created_at: archived_on
                  )
                end
                # Currently, there is no way to restore archived results

                # Add some comments
                for _ in 1..nr_comments
                  generate_fake_result_comment(result) if rand <= RATIO_COMMENTS
                end
              end
            end
          end

          puts "Generating fake reports..."
          Experiment.find_each do |experiment|
            project = experiment.project
            for _ in 1..nr_reports
              taken_project_names = []
              begin
                name = Faker::Company.bs
                user = pluck_random(project.users)
              end while [user, name].in? taken_project_names
              taken_project_names << [user, name]

              report = Report.create(
                name: name,
                description: Faker::Hipster.sentence,
                project: project,
                user: user
              )

              # Generate the oh-so-many report elements
              ReportElement.create(
                sort_order: 0,
                position: 0,
                report: report,
                type_of: :project_header
              )
              experiment.my_modules.each do |my_module|
                if rand <= RATIO_REPORT_ELEMENTS then
                  re_my_module = ReportElement.create(
                    sort_order: rand <= 0.5 ? 0 : 1,
                    position: 0,
                    report: report,
                    type_of: :my_module,
                    my_module: my_module
                  )

                  my_module.protocol.completed_steps.each do |step|
                    if rand <= RATIO_REPORT_ELEMENTS then
                      re_step = ReportElement.create(
                        sort_order: rand <= 0.5 ? 0 : 1,
                        position: 0,
                        report: report,
                        type_of: :step,
                        step: step,
                        parent: re_my_module
                      )

                      step.checklists.each do |checklist|
                        if rand <= RATIO_REPORT_ELEMENTS then
                          ReportElement.create(
                            sort_order: rand <= 0.5 ? 0 : 1,
                            position: 0,
                            report: report,
                            type_of: :step_checklist,
                            checklist: checklist,
                            parent: re_step
                          )
                        end
                      end
                      step.assets.each do |asset|
                        if rand <= RATIO_REPORT_ELEMENTS then
                          ReportElement.create(
                            sort_order: rand <= 0.5 ? 0 : 1,
                            position: 0,
                            report: report,
                            type_of: :step_asset,
                            asset: asset,
                            parent: re_step
                          )
                        end
                      end
                      step.tables.each do |table|
                        if rand <= RATIO_REPORT_ELEMENTS then
                          ReportElement.create(
                            sort_order: rand <= 0.5 ? 0 : 1,
                            position: 0,
                            report: report,
                            type_of: :step_table,
                            table: table,
                            parent: re_step
                          )
                        end
                      end
                      if rand <= RATIO_REPORT_ELEMENTS then
                        ReportElement.create(
                          sort_order: rand <= 0.5 ? 0 : 1,
                          position: 0,
                          report: report,
                          type_of: :step_comments,
                          step: step,
                          parent: re_step
                        )
                      end
                    end
                  end

                  my_module.results.each do |result|
                    if rand <= RATIO_REPORT_ELEMENTS then
                      if result.is_asset
                        type_of = :result_asset
                      elsif result.is_table
                        type_of = :result_table
                      else
                        type_of = :result_text
                      end
                      re_result = ReportElement.create(
                        sort_order: rand <= 0.5 ? 0 : 1,
                        position: 0,
                        report: report,
                        type_of: type_of,
                        result: result,
                        parent: re_my_module
                      )

                      if rand <= RATIO_REPORT_ELEMENTS then
                        ReportElement.create(
                          sort_order: rand <= 0.5 ? 0 : 1,
                          position: 0,
                          report: report,
                          type_of: :result_comments,
                          result: result,
                          parent: re_result
                        )
                      end
                    end
                  end

                  if rand <= RATIO_REPORT_ELEMENTS then
                    ReportElement.create(
                      sort_order: rand <= 0.5 ? 0 : 1,
                      position: 0,
                      report: report,
                      type_of: :my_module_activity,
                      my_module: my_module,
                      parent: re_my_module
                    )
                  end

                  if rand <= RATIO_REPORT_ELEMENTS then
                    ReportElement.create(
                      sort_order: rand <= 0.5 ? 0 : 1,
                      position: 0,
                      report: report,
                      type_of: :my_module_samples,
                      my_module: my_module,
                      parent: re_my_module
                    )
                  end
                end
              end

              # Shuffle the report
              shuffle_report_elements(
                report.report_elements.where(parent: nil)
              )
            end
          end

        end

        # Now, at the end, add additional "private" organization
        # to each user
        User.find_each do |user|
          create_private_user_organization(user, DEFAULT_PRIVATE_ORG_NAME)
        end

        # Generate thumbnails of all experiments
        Experiment.find_each do |experiment|
          experiment.generate_workflow_img
        end

        # Calculate space taken by each organization; this must
        # be done in a separate transaction because the estimated
        # asset sizes are calculated in after_commit, which is done
        # after the first transaction is completed
        ActiveRecord::Base.transaction do
          puts "Calculating organization sizes..."
          Organization.find_each do |org|
            org.calculate_space_taken
            org.save
          end
        end
      rescue ActiveRecord::ActiveRecordError,
        ArgumentError, ActiveRecord::RecordNotSaved => e
        puts "Error seeding fake data, transaction reverted"
        puts "Output: #{e.inspect}"
        puts e.backtrace.join("\n")
      end
    end
  end

  def generate_fake_protocol(
    organization,
    my_module,
    nr_steps,
    nr_comments
  )
    protocol = nil
    if my_module.present?
      protocol = my_module.protocol
      users = my_module.experiment.project.users
      author = pluck_random(users)
      if rand <= THRESHOLD_PROTOCOL_IN_MODULE_LINKED &&
        (parent = pluck_random(
          organization.protocols.where(protocol_type: [
            Protocol.protocol_types[:in_repository_private],
            Protocol.protocol_types[:in_repository_public]
          ]))
        ).present?
        protocol.protocol_type = :linked
        protocol.added_by = author
        protocol.parent = parent
        protocol.parent_updated_at = parent.updated_at
      else
        protocol.protocol_type = :unlinked
      end
      protocol.my_module = my_module
    else
      protocol = Protocol.new
      users = organization.users
      author = pluck_random(users)
      val = rand
      if val > THRESHOLD_PROTOCOL_ARCHIVED
        if val > THRESHOLD_PROTOCOL_PUBLIC
          protocol.protocol_type = :in_repository_public
          protocol.published_on = Faker::Time.backward(500)
        else
          protocol.protocol_type = :in_repository_private
        end
      else
        protocol.protocol_type = :in_repository_archived
        protocol.archived_by = author
        protocol.archived_on = Faker::Time.backward(500)
      end
      protocol.added_by = author
      protocol.authors = Faker::Book.author
      protocol.description = Faker::Lorem.paragraph(2)
    end
    protocol.name = Faker::Hacker.ingverb
    protocol.organization = organization

    if protocol.invalid? then
      rename_record(protocol, :name)
    end

    protocol.save!

    organization.protocol_keywords.find_each do |kw|
      if rand <= RATIO_PROTOCOL_KEYWORDS
        ProtocolProtocolKeyword.create(
          protocol: protocol,
          protocol_keyword: kw
        )
      end
    end

    protocol.reload
    if protocol.linked?
      # For linked protocols, simply copy their parents' contents
      protocol.load_from_repository(protocol.parent, author)
    else
      # Generate fake protocol data
      for i in 1..nr_steps
        created_at = Faker::Time.backward(500)
        completed = protocol.in_repository? ? false : (rand <= RATIO_STEP_COMPLETED)
        completed_on = completed ?
          Faker::Time.between(created_at, DateTime.now) : nil

        step = Step.create(
          created_at: created_at,
          name: Faker::Hacker.ingverb,
          description: Faker::Hacker.say_something_smart,
          position: i - 1,
          completed: completed,
          user: pluck_random(users),
          protocol: protocol,
          completed_on: completed_on
        )
        if protocol.in_module?
          Activity.create(
            type_of: :create_step,
            project: my_module.experiment.project,
            my_module: my_module,
            user: step.user,
            created_at: created_at,
            message: I18n.t(
              "activities.create_step",
              user: step.user.full_name,
              step: i,
              step_name: step.name
            )
          )
        end
        if completed then
          Activity.create(
            type_of: :complete_step,
            project: my_module.experiment.project,
            my_module: my_module,
            user: step.user,
            created_at: completed_on,
            message: I18n.t(
              "activities.complete_step",
              user: step.user.full_name,
              step: i,
              step_name: step.name,
              completed: i,
              all: i
            )
          )
        end

        # Add checklists
        for _ in 1..NR_MAX_STEP_ATTACHMENTS
          if rand <= RATIO_STEP_ATTACHMENTS then
            checklist = Checklist.create(
              name: Faker::Hacker.noun,
              step: step,
              created_by: step.user,
            )

            # Add checklist items
            for j in 1..NR_MAX_CHECKLIST_ITEMS
              if rand <= RATIO_CHECKLIST_ITEM then
                checked = protocol.in_repository? ? false : (rand <= RATIO_CHECKLIST_ITEM_CHECKED)
                checked_on = Faker::Time.backward(500)
                ci = ChecklistItem.create(
                  created_at: checked_on,
                  text: Faker::Hipster.sentence,
                  checklist: checklist,
                  checked: checked,
                  created_by: step.user
                )
                if checked then
                  Activity.create(
                    type_of: :check_step_checklist_item,
                    project: my_module.experiment.project,
                    my_module: my_module,
                    user: step.user,
                    created_at: checked_on,
                    message: I18n.t(
                      "activities.check_step_checklist_item",
                      user: step.user.full_name,
                      checkbox: ci.text,
                      completed: j,
                      all: j,
                      step: i,
                      step_name: step.name
                    )
                  )
                end
              end
            end
          end
        end

        # Add assets
        for _ in 1..NR_MAX_STEP_ATTACHMENTS
          if rand <= RATIO_STEP_ATTACHMENTS then
            asset = Asset.create(
              file: generate_file(rand(MIN_FILE_SIZE..MAX_FILE_SIZE)),
              estimated_size: 0,
              file_present: true,
              created_by: step.user
            )
            StepAsset.create(
              step: step,
              asset: asset
            )
          end
        end

        # Add tables
        for _ in 1..NR_MAX_STEP_ATTACHMENTS
          if rand <= RATIO_STEP_ATTACHMENTS then
            table = Table.create(
              contents:
                generate_table_contents(rand(30), rand(150)),
              created_by: step.user
            )
            StepTable.create(
              step: step,
              table: table
            )
          end
        end

        # Add some comments (only on protocols on module)
        if protocol.in_module? then
          for _ in 1..nr_comments
            if rand <= RATIO_COMMENTS
              user = pluck_random(users)
              created_at = Faker::Time.backward(500)
              step.comments << Comment.create(
                user: user,
                message: Faker::Hipster.sentence,
                created_at: created_at
              )
              Activity.create(
                type_of: :add_comment_to_step,
                project: my_module.experiment.project,
                my_module: my_module,
                user: user,
                created_at: created_at,
                message: I18n.t(
                  "activities.add_comment_to_step",
                  user: user.full_name,
                  step: i,
                  step_name: step.name
                )
              )
            end
          end
        end
      end
    end

    return protocol.reload
  end

  def shuffle_report_elements(report_elements)
    if report_elements.blank? or report_elements.count == 0
      return
    end

    header = report_elements.find_by(type_of: :project_header)
    if header.present?
      header.position = 0
      header.save
      i = 1
    else
      i = 0
    end

    ids_map = (i..(report_elements.count - 1)).to_a.shuffle
    for i in i..(report_elements.count - 1)
      re = report_elements[i]
      re.position = ids_map[i]
      re.save
    end

    # Recursively shuffle children
    report_elements.each do |re2|
      if re2.children.count > 0
        shuffle_report_elements(re2.children)
      end
    end
  end

  def generate_fake_project_comment(project)
    user = pluck_random(project.users)
    created_at = Faker::Time.backward(500)
    project.comments << Comment.create(
      user: user,
      message: Faker::Hipster.sentence,
      created_at: created_at
    )
    Activity.create(
      type_of: :add_comment_to_project,
      user: user,
      project: project,
      created_at: created_at,
      message: I18n.t('activities.add_comment_to_project',
                      user: user.full_name,
                      project: project.name)
    )
  end

  def generate_fake_module_comment(my_module)
    user = pluck_random(my_module.experiment.project.users)
    created_at = Faker::Time.backward(500)
    my_module.comments << Comment.create(
      user: user,
      message: Faker::Hipster.sentence,
      created_at: created_at
    )
    Activity.create(
      type_of: :add_comment_to_module,
      user: user,
      project: my_module.experiment.project,
      my_module: my_module,
      created_at: created_at,
      message: I18n.t('activities.add_comment_to_module',
                      user: user.full_name,
                      module: my_module.name)
    )
  end

  def generate_fake_result_comment(result)
    user = pluck_random(result.my_module.experiment.project.users)
    created_at = Faker::Time.backward(500)
    result.comments << Comment.create(
      user: user,
      message: Faker::Hipster.sentence,
      created_at: created_at
    )
    Activity.create(
      type_of: :add_comment_to_result,
      project: result.my_module.experiment.project,
      my_module: result.my_module,
      user: user,
      created_at: created_at,
      message: I18n.t(
        'activities.add_comment_to_result',
        user: user.full_name,
        result: result.name
      )
    )
  end

  def generate_fake_step_comment(step)
    user = pluck_random(step.protocol.my_module.experiment.project.users)
    created_at = Faker::Time.backward(500)
    step.comments << Comment.create(
      user: user,
      message: Faker::Hipster.sentence,
      created_at: created_at
    )
    Activity.create(
      type_of: :add_comment_to_step,
      project: step.protocol.my_module.experiment.project,
      my_module: step.protocol.my_module,
      user: user,
      created_at: created_at,
      message: I18n.t(
        "activities.add_comment_to_step",
        user: user.full_name,
        step: step.position + 1,
        step_name: step.name
      )
    )
  end

  # WARNING: This only works on PostgreSQL
  def pluck_random(scope)
    scope.order("RANDOM()").first
  end

  # Randomly determine whether project/module/result is active (0),
  # archived (1), or already restored (2)
  def random_status
    val = rand
    status = :active
    if val > THRESHOLD_ARCHIVED
      if val > THRESHOLD_RESTORED
        status = :archived
      end
    else
      status = :restored
    end
    status
  end
end
