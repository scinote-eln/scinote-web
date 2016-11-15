module Users
  class InvitationsController < Devise::InvitationsController
    def update
      # Instantialize a new organization with the provided name
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
      unless @org.valid?
        # Find the user being invited
        resource = User.find_by_invitation_token(
          update_resource_params[:invitation_token],
          false
        )

        # Check if user's data (passwords etc.) is valid
        resource.assign_attributes(
          update_resource_params.except(:invitation_token)
        )
        resource.valid? # Call validation to generate errors

        # In any case, add the organization name error
        resource.errors.add(:base, @org.errors.to_a.first)
        return resource
      end

      super
    end
  end
end
