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
