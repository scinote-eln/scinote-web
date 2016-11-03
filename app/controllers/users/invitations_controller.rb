class Users::InvitationsController < Devise::InvitationsController

  def update
    @org = Organization.new
    @org.name = params[:organization][:name]

    super do |user|
      if user.errors.empty?
        @org.created_by = user
        @org.save

        UserOrganization.create(
          user: user,
          organization: @org,
          role: 'admin'
        )
      end
    end
  end

  def accept_resource
    resource = super

    if not @org.valid?
      resource.errors.add(:base, @org.errors.to_a.first)
    end

    resource
  end

  def invite_users
    # TODO
  end
end
