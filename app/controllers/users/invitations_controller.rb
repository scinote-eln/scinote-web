module Users
  class InvitationsController < Devise::InvitationsController
    include UsersGenerator

    before_action :check_invite_users_permission, only: :invite_users

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
      resource.errors.add(:base, @org.errors.to_a.first) unless @org.valid?
      resource
    end

    def invite_users
      @invite_results = []
      @too_many_emails = false

      cntr = 0
      @emails.each do |email|
        cntr += 1

        if cntr > Constants::INVITE_USERS_LIMIT
          @too_many_emails = true
          break
        end

        password = generate_user_password

        # Check if user already exists
        user = nil
        user = User.find_by_email(email) if User.exists?(email: email)

        result = { email: email }

        if user.present?
          result[:status] = :user_exists
          result[:user] = user
        else
          # Validate the user data
          error = !(Constants::BASIC_EMAIL_REGEX === email)
          error = validate_user(email, email, password).count > 0 unless error

          if !error
            user = User.invite!(
              full_name: email,
              email: email,
              initials: email.upcase[0..1],
              skip_invitation: true
            )

            result[:status] = :user_created
            result[:user] = user

            # Sending email invitation is done in background job to prevent
            # issues with email delivery. Also invite method must be call
            # with :skip_invitation attribute set to true - see above.
            user.delay.deliver_invitation
          else
            # Return invalid status
            result[:status] = :user_invalid
          end
        end

        if @org.present? && result[:status] != :user_invalid
          if UserOrganization.exists?(user: user, organization: @org)
            user_org =
              UserOrganization.where(user: user, organization: @org).first

            result[:status] = :user_exists_and_in_org
          elsif result[:status] == :user_exists && !user.confirmed?
            # We don't want to allow inviting unconfirmed
            # users (that were not invited as part of this action)
            # into organizations
            result[:status] = :user_exists_unconfirmed
          else
            # Also generate user organization relation
            user_org = UserOrganization.new(
              user: user,
              organization: @org,
              role: @role
            )
            user_org.save

            generate_notification(
              @user,
              user,
              user_org.role_str,
              user_org.organization
            )

            if result[:status] == :user_exists
              result[:status] = :user_exists_invited_to_org
            else
              result[:status] = :user_created_invited_to_org
            end
          end

          result[:user_org] = user_org
        end

        @invite_results << result
      end

      respond_to do |format|
        format.json do
          render json: {
            html: render_to_string(
              partial: 'shared/invite_users_modal_results.html.erb'
            )
          }
        end
      end
    end

    private

    def generate_notification(user, target_user, role, org)
      title = I18n.t('notifications.assign_user_to_organization',
                     assigned_user: target_user.name,
                     role: role,
                     organization: org.name,
                     assigned_by_user: user.name)

      message = "#{I18n.t('search.index.organization')} #{org.name}"
      notification = Notification.create(
        type_of: :assignment,
        title: ActionController::Base.helpers.sanitize(title),
        message: ActionController::Base.helpers.sanitize(message)
      )

      if target_user.assignments_notification
        UserNotification.create(notification: notification, user: target_user)
      end
    end

    def check_invite_users_permission
      @user = current_user
      @emails = params[:emails]
      @org = Organization.find_by_id(params['organizationId'])
      @role = params['role']

      render_403 if @emails && @emails.empty?
      render_403 if @org && !is_admin_of_organization(@org)
      render_403 if @role && !UserOrganization.roles.keys.include?(@role)
    end
  end
end
