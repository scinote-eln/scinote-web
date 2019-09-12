Given(/^I'm on the Protocols page of a "([^"]*)" task$/) do |task_name|
  task = MyModule.find_by_name(task_name)
  visit protocols_my_module_path(task)
end

Then(/^I should see "([^"]*)" attachment on "([^"]*)" step$/) do |file, step_name|
  wait_for_ajax
  expect(find('.step', text: step_name)).to have_content(file)
end
