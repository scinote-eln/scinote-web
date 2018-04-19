# Import all RAP Information from Excel into the database using the four rap models.
require 'spreadsheet'
file_name = "rap_info_april_12_2018.xls"
namespace :import do
  desc "Import RAP Information from Excel"
  task rap_excel: :environment do
    # Perform the task...
    excel_data = Spreadsheet.open file_name
    sheet = excel_data.worksheet 0
    programLevel = nil
    topicLevel = nil
    projectLevel = nil
    taskLevel = nil
    byebug
    sheet.each do |row|
      # iterate through each cel
      col = 0
      row.each do |cell|
        # if cell is empty, look at next cell
        if cell.nil || cell.empty
          #Look at next cell
          col += 1
          # If col reaches > 3 without finding any values, then we've finished the file.
          if col > 3
            break
          end
          next
        else
          # else we found a value we want to record, we should break after this and go to next row
          if col === 0
            # RapProgramLevel is top level, so just save it to the database.
            programLevel = RapProgramLevel.create(name: cell)
          elsif col === 1
            # RapTopicLevel is nested level, so we need to save it to the database with a reference to RapProgramLevel
            #topicLevel = RapTopicLevel.create(name: cell, rap_program_level_id: programLevel.id)
            topicLevel = programLevel.rap_topic_levels.create(name: cell)
          elsif col === 2
            # RapProjectLevel is nested level, so we need to save it to the database with a reference to RapTopicLevel
            #projectLevel = RapProjectLevel.create(name: cell, rap_topic_level_id: topicLevel.id)
            projectLevel = topicLevel.rap_project_levels.create(name: cell)
          elsif col === 3
            # RapTaskLevel is nested level, so we need to save it to the database with a reference to RapProjectLevel
            #taskLevel = RapTaskLevel.create(name: cell, rap_project_level_id: projectLevel.id)
            taskLevel = topicLevel.rap_task_levels.create(name: cell)
          end
          break # Go to next row
        end
      end
    end
  end
end