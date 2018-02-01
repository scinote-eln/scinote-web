module Users
  class InvitationsController < Devise::InvitationsController
    include InputSanitizeHelper
    include UsersGenerator

    prepend_before_action :check_captcha, only: [:update]

    before_action :check_invite_users_permission, only: :invite_users

    before_action :update_sanitized_params, only: :update

    def update
      return super unless Rails.configuration.x.new_team_on_signup
      # Instantialize a new team with the provided name
      @team = Team.new
      @team.name = params[:team][:name]

      super do |user|
        if user.errors.empty?
          @team.created_by = user
          @team.save

          UserTeam.create(
            user: user,
            team: @team,
            role: 'admin'
          )
        end
      end
    end

    def accept_resource
      return super unless Rails.configuration.x.new_team_on_signup

      unless @team.valid?
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

        # In any case, add the team name error
        resource.errors.add(:base, @team.errors.to_a.first)
        return resource
      end

      super
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
            user.update(invited_by: @user)

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

        if @team.present? && result[:status] != :user_invalid
          if UserTeam.exists?(user: user, team: @team)
            user_team =
              UserTeam.where(user: user, team: @team).first

            result[:status] = :user_exists_and_in_team
          else
            # Also generate user team relation
            user_team = UserTeam.new(
              user: user,
              team: @team,
              role: @role
            )
            user_team.save

            generate_notification(
              @user,
              user,
              user_team.role_str,
              user_team.team
            )

            if result[:status] == :user_exists && !user.confirmed?
              result[:status] = :user_exists_unconfirmed_invited_to_team
            elsif result[:status] == :user_exists
              result[:status] = :user_exists_invited_to_team
            else
              result[:status] = :user_created_invited_to_team
            end
          end

          result[:user_team] = user_team
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

    def update_sanitized_params
      # Solution for Devise < 4.0.0
      devise_parameter_sanitizer.permit(:accept_invitation, keys: [:full_name])
    end

    def check_captcha
      if Rails.configuration.x.enable_recaptcha
        unless verify_recaptcha
          self.resource = resource_class.new
          resource.invitation_token = update_resource_params[:invitation_token]
          respond_with_navigational(resource) { render :edit }
        end
      end
    end

    def generate_notification(user, target_user, role, team)
      title = I18n.t('notifications.assign_user_to_team',
                     assigned_user: target_user.name,
                     role: role,
                     team: team.name,
                     assigned_by_user: user.name)

      message = "#{I18n.t('search.index.team')} #{team.name}"
      notification = Notification.create(
        type_of: :assignment,
        title: sanitize_input(title),
        message: sanitize_input(message)
      )

      if target_user.assignments_notification
        UserNotification.create(notification: notification, user: target_user)
      end
    end

    def check_invite_users_permission
      @user = current_user
      @emails = params[:emails].map(&:downcase)
      @team = Team.find_by_id(params['teamId'])
      @role = params['role']

      render_403 if @emails && @emails.empty?
      render_403 if @team && !can_manage_team_users?(@team)
      render_403 if @role && !UserTeam.roles.keys.include?(@role)
    end
  end
end
