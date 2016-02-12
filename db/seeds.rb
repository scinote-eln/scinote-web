include UsersGenerator

# Create admin user
admin_password = "inHisHouseAtRlyehDeadCthulhuWaitsDreaming"
create_user(
  "Admin",
  "admin@scinote.net",
  admin_password,
  true,
  DEFAULT_PRIVATE_ORG_NAME,
  []
)