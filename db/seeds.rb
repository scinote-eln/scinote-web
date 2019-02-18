include UsersGenerator

if User.count.zero?
  if ENV['ADMIN_NAME'].present? &&
     ENV['ADMIN_EMAIL'].present? &&
     ENV['ADMIN_PASSWORD'].present?
    admin_name = ENV['ADMIN_NAME']
    admin_email = ENV['ADMIN_EMAIL']
    admin_password = ENV['ADMIN_PASSWORD']
  else
    admin_name = 'Admin'
    admin_email = 'admin@scinote.net'
    admin_password = 'inHisHouseAtRlyehDeadCthulhuWaitsDreaming'
  end

  # Create admin user
  create_user(
    admin_name,
    admin_email,
    admin_password,
    true,
    Constants::DEFAULT_PRIVATE_TEAM_NAME,
    [],
    Extends::INITIAL_USER_OPTIONS
  )
end


if Team.count == 1
  20.times do |i|
    new_team=Team.create(name: "Team #{i}", created_by_id: 1)
    UserTeam.create(role:1, user_id: 1, team_id: new_team.id, assigned_by_id: 1)
  end
end

if User.count == 1
  50.times do |i|
    create_user(
      "User#{i}",
      "user#{i}@mail.ru",
      "1234567890",
      true,
      nil,
      Team.all.sample(3).pluck(:id),
      Extends::INITIAL_USER_OPTIONS
    )
  end
end