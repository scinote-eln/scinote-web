# frozen_string_literal: true

def check_active_team(team)
  expect(page).to have_selector '#team-switch button', text: team
end
