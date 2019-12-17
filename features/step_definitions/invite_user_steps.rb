
Given("Settings page of BioSistemika Process team of a Karli Novak user") do 
  visit "/users/settings/teams/1"
end

Then("I fill in {string} to Invite users to team BioSistemika Process input field") do |email|
  page.find('.bootstrap-tagsinput>input').set email
end

Then("I click on {string} in Invite dropdown") do |text1|
  find("[data-role='invite-with-role-div'] a" ,text: text1).click
end

Then('I should see {string} massage of {string} modal window') do |massage, modal|
  modal_object = page.find('.modal-content', text: modal)
  expect(modal_object).to have_selector '.results-wrap', text: massage
end

Given("I click on Sign up button") do
  find('.btn').click
end
