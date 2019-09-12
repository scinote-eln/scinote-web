Given(/^I'm on the Results page of a "([^"]*)" task$/) do |task_name|
  task = MyModule.find_by_name(task_name)
  visit results_my_module_path(task)
end

Given(/^I click edit "(.+)" result icon$/) do |result_name|
  find('.panel-heading', text: result_name).find('.edit-result-asset').click
end
