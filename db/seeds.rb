include UsersGenerator
# TODO is this right? Can't find the RapGenerator include...
require "#{Rails.root}/app/utilities/rap_generators"
include RapGenerator

if User.count.zero?
  if ENV['ADMIN_NAME'].present? &&
     ENV['ADMIN_EMAIL'].present? &&
     ENV['ADMIN_PASSWORD'].present?
    admin_name = ENV['ADMIN_NAME']
    admin_email = ENV['ADMIN_EMAIL']
    admin_password = ENV['ADMIN_PASSWORD']
    admin_name = 'Admin'
    admin_email = 'young.daniel@epa.gov'
    admin_password = '***REMOVED***'
  else
    admin_name = 'Admin'
    admin_email = 'young.daniel@epa.gov'
    admin_password = '***REMOVED***'
  end

  # Create admin user
  create_user(
    admin_name,
    admin_email,
    admin_password,
    true,
    Constants::DEFAULT_PRIVATE_TEAM_NAME,
    [],
    Extends::INITIAL_USER_OPTIONS
  )
end

#########################################################################
# Try to insert the REGIONAL requirement for RAP data, RAP Not Required #
#########################################################################
rapNotRequired = "RAP Not Required"
unless RapProgramLevel.exists?(:name => rapNotRequired)
  create_rap_program_level(rapNotRequired)
end

unless RapTopicLevel.exists?(:name => rapNotRequired)
  # Get the corresponding parent rap_program_level_id before creating a new RapTopicLevel
  # program_id = RapProgramLevel.find(:name => programLevelName).id
  program_id = RapProgramLevel.where(name: rapNotRequired).take.id
  create_rap_topic_level(rapNotRequired, program_id)
end

unless RapProjectLevel.exists?(:name => rapNotRequired)
  # Get the corresponding parent rap_topic_level_id before creating a new RapProjectLevel
  # topic_id = RapTopicLevel.find(:name => topicLevelName).id
  topic_id = RapTopicLevel.where(name: rapNotRequired).take.id
  create_rap_project_level(rapNotRequired, topic_id)
end

unless RapTaskLevel.exists?(:name => rapNotRequired)
  # Get the corresponding parent rap_project_level_id before creating a new RapTaskLevel
  # project_id = RapProjectLevel.find(:name => projectLevelName).id
  project_id = RapProjectLevel.where(name: rapNotRequired).take.id
  create_rap_task_level(rapNotRequired, project_id)
end

# Seed RAP data, copy logic from the ruby SQL generator script inside 'manual_scripts'
# rap_program_level is the highest point of the RAP hierarchy, so if that's 0 then the rest must be 0 as well
if RapProgramLevel.count.zero?
  # Import all RAP Information from Excel into the database using the four rap models.
  require 'spreadsheet'
  all_inserts = []
  in_file_name = "./rap_info_april_12_2018.xls"
  excel_data = Spreadsheet.open in_file_name
  sheet = excel_data.worksheet 0
  programLevelName = ""
  topicLevelName = ""
  projectLevelName = ""
  taskLevelName = ""
  created = Time.now.strftime('%B %d, %Y')
  
  sheet.each 2 do |row|
    # iterate through each cell
    col = 0
    row.each do |cell|
      # if cell is empty, look at next cell
      if cell.nil? || cell.empty?
        #Look at next cell
        col += 1
        # If col reaches > 3 without finding any values, then we've finished the file.
        if col > 3
          break
        end
        next
      else
        # We need to make sure the quotes in the output string (sql script) are broken out
        if cell.casecmp("Not Applicable") == 0
          # do nothing

        # else we found a value we want to record, we should break after this and go to next row
        elsif col === 0
          programLevelName = cell.gsub("'", "''")
          if RapProgramLevel.exists?(:name => programLevelName)
            # skip this one
          else
            create_rap_program_level(programLevelName)
          end

        elsif col === 1
          topicLevelName = cell.gsub("'", "''")
          if RapTopicLevel.exists?(:name => topicLevelName)
            # skip this one
          else
            # Get the corresponding parent rap_program_level_id before creating a new RapTopicLevel
            # program_id = RapProgramLevel.find(:name => programLevelName).id
            program_id = RapProgramLevel.where(name: programLevelName).take.id
            create_rap_topic_level(topicLevelName, program_id)
          end

        elsif col === 2
          projectLevelName = cell.gsub("'", "''")
          if RapProjectLevel.exists?(:name => projectLevelName)
            # skip this one
          else
            # Get the corresponding parent rap_topic_level_id before creating a new RapProjectLevel
            # topic_id = RapTopicLevel.find(:name => topicLevelName).id
            topic_id = RapTopicLevel.where(name: topicLevelName).take.id
            create_rap_project_level(projectLevelName, topic_id)
          end

        elsif col === 3
          taskLevelName = cell.gsub("'", "''")
          if RapTaskLevel.exists?(:name => taskLevelName)
            # skip this one
          else
            # Get the corresponding parent rap_project_level_id before creating a new RapTaskLevel
            # project_id = RapProjectLevel.find(:name => projectLevelName).id
            project_id = RapProjectLevel.where(name: projectLevelName).take.id
            create_rap_task_level(taskLevelName, project_id)
          end
        end
        break # Go to next row
      end # end of cell not nil
    end # end of each cell
  end # end of each row
end # end of RapProgramLevel.count.zero?

# TODO If any Project database entries are missing their rap_task_level_id values, then we need to set a default.
# if RapProgramLevel.exists?(:rap_task_level_id => nil)
# rap_task_level_id = RapTaskLevel.minimum(:id)
  
# end
