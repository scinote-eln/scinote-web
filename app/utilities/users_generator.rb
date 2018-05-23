module UsersGenerator
  # Simply validate the user with the given data,
  # and return an array of errors (which is 0-length
  # if user is valid)
  def validate_user(
    full_name,
    email,
    password
  )
    nu = User.new(full_name: full_name,
                  initials: get_user_initials(full_name),
                  email: email,
                  password: password)
    nu.validate
    nu.errors
  end

  # If confirmed == true, the user is automatically confirmed;
  # otherwise, SciNote sends the "confirmation" email to the user
  # If private_team_name == nil, private taem is not created.
  def create_user(full_name,
                  email,
                  password,
                  confirmed,
                  private_team_name,
                  team_ids,
                  options = {})
    nu = User.new({ full_name: full_name,
                    initials: get_user_initials(full_name),
                    email: email,
                    password: password,
                    password_confirmation: password }.merge(options))

    nu.confirmed_at = Time.now if confirmed
    nu.save!

    # TODO: If user is not confirmed, maybe additional email
    # needs to be sent with his/her password & email?

    # Create user's own team of needed
    if private_team_name.present?
      create_private_user_team(nu, private_team_name)
    end

    # Assign user to additional teams
    team_ids.each do |team_id|
      team = Team.find_by_id(team_id)
      UserTeam.create(user: nu, team: team, role: :admin) if team.present?
    end

    # Assign user team as user current team
    nu.current_team_id = nu.teams.first.id unless nu.teams.empty?
    nu.save!

    nu.reload
    nu
  end

  def create_private_user_team(user, private_team_name)
    no = Team.create(name: private_team_name, created_by: user)
    UserTeam.create(user: user, team: no, role: :admin)
  end

  def print_user(user, password)
    puts "USER ##{user.id}"
    puts "  Full name: #{user.full_name}"
    puts "  Initials: #{user.initials}"
    puts "  Email: #{user.email}"
    puts "  Password: #{password}"
    puts "  Confirmed at: #{user.confirmed_at}"
    teams = user.teams.collect(&:name).join(', ')
    puts "  Member of teams: #{teams}"
  end

  def generate_user_password
    require 'securerandom'
    SecureRandom.hex(5)
  end

  def get_user_initials(full_name)
    full_name.split(' ').collect { |n| n.capitalize[0] }.join[0..3]
  end
end
