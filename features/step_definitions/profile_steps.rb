Then(/^I click on Avatar$/) do
  find('img.avatar').click
end

Given(/^I'm on the profile page$/) do
  visit edit_user_registration_path
end

Then(/^I click on Browse button$/) do
  find('input#user_avatar').click
end
