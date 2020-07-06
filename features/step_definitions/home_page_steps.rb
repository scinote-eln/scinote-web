Then("I should see {string} public project card in {string} team page") do |project, team|
  expect(page).to have_selector '.nav-name', text: team
  expect(page).to have_selector '.panel-project a', text: project
  expect(page).to have_selector '.panel-project span', text: 'All team members'
end

Then("I should see {string} private project card in {string} team page") do |project, team|
  expect(page).to have_selector '.nav-name', text: team
  expect(page).to have_selector '.panel-project a', text: project
  expect(page).to have_selector '.panel-project span', text: 'Project members only'
end

Then("I should see {string} error message of {string} modal window") do |message, modal|
  modal_object = page.find('.modal-content', text: modal)
  expect(modal_object).to have_selector '.help-block', text: message
end

Given("I had project {string} for team {string}") do |project, team|
  FactoryBot.create(:project, name: project, team: Team.find_by(name: team))
end

Then("I click to down arrow of a {string} project card") do |project|
  page.find('.panel-project', text: project).hover.find('.caret').click
end

Then("user {string} owner of project {string}") do |user, project|
  FactoryBot.create(:user_project, role: 0, user: User.find_by(full_name: user), project: Project.find_by(name: project))
end

Then("user {string} normal user of project {string}") do |user, project|
  FactoryBot.create(:user_project, role: 1, user: User.find_by(full_name: user), project: Project.find_by(name: project))
end

Given("I click to {string} of a Options modal window") do |link|
   page.find('.panel-project .dropdown-menu', text: 'Options').find('a', text: link).click
end

Then("I click {string} icon on {string} project card") do |icon, project|
  page.find('.panel-project', text: project).find(".fa-#{icon}").click
end

Then("I select user {string} in user dropdown of user manage modal for project {string}") do |user, project|
  within('.modal-content', text: "Manage users for #{project}") do
    find('.btn[data-id="user_project_user_id"]').click
    find('.dropdown-menu.open a', text: user).click
  end
end

Then("I select role {string} in role dropdown of user manage modal for project {string}") do |role, project|
  within('.modal-content', text: "Manage users for #{project}") do
    find('.btn[title="Select Role"]').click
    find('.dropdown-menu a', text: role).click
  end
end

Then("I change role {string} in role dropdown for user {string} of user manage modal for project {string}") do |role, user, project|
  within('.modal-content', text: "Manage users for #{project}") do
    within('.row', text: user) do
      find('.btn[title="Change Role"]').click
      find('.dropdown-menu a', text: role).click
    end
  end
end

Then("I should see {string} with role {string} in Users list of {string} project card") do |user, role, project|
  within('.panel-project', text: project) do
    within('[data-hook="project-users-tab-list"]') do
      user_row = find('.row', text: user)
      expect(user_row).to have_content(user)
      expect(user_row).to have_content(role)
    end
  end
end

Then("I should see team {string} settings page of a current user") do |team|
  expect(current_path).to eq team_path(Team.find_by(name: team))
end

