# Import all RAP Information from Excel into the database using the four rap models.
require 'spreadsheet'
file_name = "rap_info_april_12_2018.xlsx"
namespace :import do
  desc "Import RAP Information from Excel"
  task rap_excel: environment do
    # Perform the task...
    excel_data = Spreadsheet.open file_name
    sheet = excel_data.worksheet 0
    sheet.each do |row|
      # iterate through each cel
      col = 0
      row.each do |cell|
        programLevel = ""
        topicLevel = ""
        projectLevel = ""
        taskLevel = ""
        # if cell is empty, look at next cell
        if cell.nil || cell.empty
          #Look at next cell
          col += 1
          next
        else
          # else we found a value we want to record, we should break after this and go to next row
          if col === 0
            # RapProgramLevel is top level, so just save it to the database.
          elsif col === 1
            # RapTopicLevel is nested level, so we need to save it to the database with a reference to RapProgramLevel
          elsif col === 2
            # RapProjectLevel is nested level, so we need to save it to the database with a reference to RapTopicLevel
          elsif col === 3
            # RapTaskLevel is nested level, so we need to save it to the database with a reference to RapProjectLevel
          end
          break # Go to next row
        end
      end
    end
  end
end