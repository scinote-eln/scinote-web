module UsersGenerator

  # Simply validate the user with the given data,
  # and return an array of errors (which is 0-length
  # if user is valid)
  def validate_user(
    full_name,
    email,
    password
  )
    nu = User.new({
      full_name: full_name,
      initials: get_user_initials(full_name),
      email: email,
      password: password
      })
    nu.validate
    nu.errors
  end

  # If confirmed == true, the user is automatically confirmed;
  # otherwise, sciNote sends the "confirmation" email to the user
  # If private_org_name == nil, private organization is not created.
  def create_user(
    full_name,
    email,
    password,
    confirmed,
    private_org_name,
    org_ids)
    nu = User.new({
      full_name: full_name,
      initials: get_user_initials(full_name),
      email: email,
      password: password,
      password_confirmation: password
    })
    if confirmed then
      nu.confirmed_at = Time.now
    end
    nu.save!

    # TODO: If user is not confirmed, maybe additional email
    # needs to be sent with his/her password & email?

    # Create user's own organization of needed
    if private_org_name.present? then
      create_private_user_organization(nu, private_org_name)
    end

    # Assign user to additional organizations
    org_ids.each do |org_id|
      org = Organization.find_by_id(org_id)
      if org.present?
        UserOrganization.create({ user: nu, organization: org, role: :admin })
      end
    end

    # Assing user organization as user currentorganization
    nu.current_organization_id = nu.organizations.first.id
    nu.save!

    nu.reload
    return nu
  end

  def create_private_user_organization(user, private_org_name)
    no = Organization.create({ name: private_org_name, created_by: user })
    UserOrganization.create({ user: user, organization: no, role: :admin })
  end

  def print_user(user, password)
    puts "USER ##{user.id}"
    puts "  Full name: #{user.full_name}"
    puts "  Initials: #{user.initials}"
    puts "  Email: #{user.email}"
    puts "  Password: #{password}"
    puts "  Confirmed at: #{user.confirmed_at}"
    orgs = user.organizations.collect{ |org| org.name }.join(", ")
    puts "  Member of organizations: #{orgs}"
  end

  def generate_user_password
    require 'securerandom'
    SecureRandom.hex(5)
  end

  def get_user_initials(full_name)
    full_name.split(" ").collect{ |n| n.capitalize[0] }.join[0..3]
  end

end
