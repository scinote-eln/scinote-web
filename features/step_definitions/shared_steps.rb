When(/^I click '(.+)' button$/) do |button|
  click_on button
end

Then(/^I should be redirected to the homepage$/) do
  current_path.should =~ /^\/$/
end

When(/^I click '(.+)' link$/) do |link|
  click_link link
end

Then(/^I should see '(.+)'$/) do |text|
  expect(page).to have_content(text)
end

Then(/^I should be on homepage$/) do
  expect(page).to have_current_path(root_path)
end
