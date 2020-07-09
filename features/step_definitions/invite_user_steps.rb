# frozen_string_literal: true

Given('Settings page of BioSistemika Process team of a Karli Novak user') do
  visit '/users/settings/teams/1'
end

Then('I should see {string} massage of {string} modal window') do |massage, modal|
  modal_object = page.find('.modal-content', text: modal)
  expect(modal_object).to have_selector '.results-wrap', text: massage
end

