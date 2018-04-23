# Import all RAP Information from Excel into the database using the four rap models.
require 'spreadsheet'
require 'byebug'
file_name = "rap_info_april_12_2018.xls"
# Perform the task...
excel_data = Spreadsheet.open file_name
sheet = excel_data.worksheet 0
programLevelName = ""
topicLevelName = ""
projectLevelName = ""
taskLevelName = ""
programLevelIndex = 0
topicLevelIndex = 0
projectLevelIndex = 0
taskLevelIndex = 0
created = Time.now.strftime('%B %d, %Y')
sheet.each 2 do |row|
  byebug
  # iterate through each cel
  col = 0
  row.each do |cell|
    byebug
    # if cell is empty, look at next cell
    if cell.nil? || cell.empty?
      byebug
      #Look at next cell
      col += 1
      byebug
      # If col reaches > 3 without finding any values, then we've finished the file.
      if col > 3
        byebug
        break
      end
      next
    else
      byebug
      # else we found a value we want to record, we should break after this and go to next row
      if col === 0
        byebug
        programLevelName = cell
        # Check to see if this value already exists in the database.
        # If it exists, get the index. If it doesn't, get the max ID and create an insert.
        programLevelIndex = 0
        programLevelInsert = "INSERT INTO rap_program_levels VALUES ({programLevelName}, {created}), {created})"
        # Write the insert statement to our SQL file.
      elsif col === 1
        byebug
        topicLevelName = cell
        # Check to see if this value already exists in the database.
        # If it exists, get the index. If it doesn't, get the max ID and create an insert.
        topicLevelIndex = 0
        topicLevelInsert = "INSERT INTO rap_topic_levels VALUES ({topicLevelName}, {created}), {created})"
        # Write the insert statement to our SQL file.
      elsif col === 2
        byebug
        projectLevelName = cell
        # Check to see if this value already exists in the database.
        # If it exists, get the index. If it doesn't, get the max ID and create an insert.
        projectLevelIndex = 0
        projectLevelInsert = "INSERT INTO rap_project_levels VALUES ({projectLevelName}, {created}), {created})"
        # Write the insert statement to our SQL file.
      elsif col === 3
        byebug
        taskLevelName = cell
        # Check to see if this value already exists in the database.
        # If it exists, get the index. If it doesn't, get the max ID and create an insert.
        taskLevelIndex = 0
        taskLevelInsert = "INSERT INTO rap_task_levels VALUES ({taskLevelName}, {created}), {created})"
        # Write the insert statement to our SQL file.
      end
      byebug
      break # Go to next row
    end
  end
end