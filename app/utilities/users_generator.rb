# frozen_string_literal: true

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

    nu.confirmed_at = Time.zone.now if confirmed
    nu.save!

    # TODO: If user is not confirmed, maybe additional email
    # needs to be sent with his/her password & email?

    # Create user's own team of needed
    create_private_user_team(nu, private_team_name) if private_team_name.present?

    # Assign user to additional teams
    team_ids.each do |team_id|
      team = Team.find_by(id: team_id)
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
    password = SecureRandom.hex(5)

    password += Devise.password_complexity.inject('') do |second_part_pass, elem|
      n = elem[1]
      random_string = case elem[0]
                      when :digit
                        rand.to_s[2..2 + n]
                      when :lower
                        (0...n).map { ('a'..'z').to_a[rand(26)] }.join
                      when :upper
                        (0...n).map { ('A'..'Z').to_a[rand(26)] }.join
                      when :symbol
                        (0...n).map do
                          ((32..47).to_a + (58..64).to_a + (91..96).to_a + (123..126).to_a)
                            .pack('U*').chars.to_a[rand(33)]
                        end.join
                      end

      second_part_pass += random_string
      second_part_pass
    end
    password
  end

  def get_user_initials(full_name)
    full_name.split(' ').collect { |n| n.capitalize[0] }.join[0..3]
  end
end
