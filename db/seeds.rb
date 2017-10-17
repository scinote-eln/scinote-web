include UsersGenerator

# Create admin user
admin_password = 'inHisHouseAtRlyehDeadCthulhuWaitsDreaming'
create_user(
  'Admin',
  'admin@scinote.net',
  admin_password,
  true,
  Constants::DEFAULT_PRIVATE_TEAM_NAME,
  []
)
