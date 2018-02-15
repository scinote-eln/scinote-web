Then(/^I click on Avatar$/) do
  find('img.avatar').click
end

Given(/^I'm on the profile page$/) do
  visit edit_user_registration_path
end

Then(/^I click on Browse button$/) do
  find('input#user_avatar').click
end

Then(/^I change "([^"]*)" with "([^"]*)" email$/) do |prev_email, new_email|
  wait_for_ajax
  find(:css, "input[value='#{prev_email}']").set(new_email)
end

Then(/^I fill in "([^"]*)" in "([^"]*)" field of "([^"]*)" form$/) do |password, field, form_id|
  within form_id do
    find(field).set(password)
  end
end
