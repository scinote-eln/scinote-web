# Import all RAP Information from Excel into the database using the four rap models.
require 'spreadsheet'
require 'byebug'

all_inserts = []
out_file_name = "rap_info_april_12_2018_insert.sql"
in_file_name = "rap_info_april_12_2018.xls"
excel_data = Spreadsheet.open in_file_name
sheet = excel_data.worksheet 0
programLevelName = ""
topicLevelName = ""
projectLevelName = ""
taskLevelName = ""
created = Time.now.strftime('%B %d, %Y')
sheet.each 2 do |row|
  # iterate through each cel
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
      # else we found a value we want to record, we should break after this and go to next row
      if col === 0
        programLevelName = cell
        # Check to see if this value already exists in the database.
        # If it exists, get the index. If it doesn't, get the max ID and create an insert.
        valuesClause = "VALUES ('#{programLevelName}', '#{created}', '#{created}')"
        programLevelInsert = "INSERT INTO rap_program_levels (name, created_at, updated_at) #{valuesClause};\n"
        all_inserts << programLevelInsert
        # Write the insert statement to our SQL file.
      elsif col === 1
        topicLevelName = cell
        # Check to see if this value already exists in the database.
        # If it exists, get the index. If it doesn't, get the max ID and create an insert.
        prevIdClause = "(SELECT id FROM rap_program_levels WHERE name = '#{programLevelName}')"
        valuesClause = "VALUES ('#{topicLevelName}',  #{prevIdClause}, '#{created}', '#{created}')"
        topicLevelInsert = "INSERT INTO rap_topic_levels (name, rap_program_level_id, created_at, updated_at) #{valuesClause};\n"
        all_inserts << topicLevelInsert
        # Write the insert statement to our SQL file.
      elsif col === 2
        projectLevelName = cell
        # Check to see if this value already exists in the database.
        # If it exists, get the index. If it doesn't, get the max ID and create an insert.
        prevIdClause = "(SELECT id FROM rap_topic_levels WHERE name = '#{topicLevelName}')"
        valuesClause = "VALUES ('#{projectLevelName}', #{prevIdClause}, '#{created}', '#{created}')"
        projectLevelInsert = "INSERT INTO rap_project_levels (name, rap_topic_level_id, created_at, updated_at) #{valuesClause};\n"
        all_inserts << projectLevelInsert
        # Write the insert statement to our SQL file.
      elsif col === 3
        taskLevelName = cell
        # Check to see if this value already exists in the database.
        # If it exists, get the index. If it doesn't, get the max ID and create an insert.
        prevIdClause = "(SELECT id FROM rap_project_levels WHERE name = '#{projectLevelName}')"
        valuesClause = "VALUES ('#{taskLevelName}',  #{prevIdClause}, '#{created}', '#{created}')"
        taskLevelInsert = "INSERT INTO rap_task_levels (name, rap_project_level_id, created_at, updated_at) #{valuesClause};\n"
        all_inserts << taskLevelInsert
        # Write the insert statement to our SQL file.
      end
      break # Go to next row
    end
  end
end
File.write(out_file_name, all_inserts.join) 