module ClientApi
  class InvitationsService
    include InputSanitizeHelper
    include UsersGenerator
    include NotificationsHelper

    def initialize(args)
      @user = args[:user]
      @emails = args[:emails]
      @team = args[:team]
      @role = args[:role]

      unless @role && UserTeam.roles.keys.include?(@role) &&
             @emails && @emails.present?
        raise ClientApi::CustomInvitationsError,
              I18n.t('client_api.invalid_arguments')
      end
      @emails = @emails.map(&:downcase)
    end

    def invitation
      invite_results = []

      @emails.each_with_index do |email, index|
        result = {}
        # Check invite users limit
        if index >= Constants::INVITE_USERS_LIMIT
          result[:status] = :too_many_emails
          result[:alert] = :danger
          result[:invite_user_limit] = Constants::INVITE_USERS_LIMIT
          invite_results << result
          break
        end

        result[:email] = email

        # Check if user already exists
        user = User.find_by_email(email) if User.exists?(email: email)
        # Handle user invitation
        result = handle_user(result, email, user)
        invite_results << result
      end
      invite_results
    end

    private

    def handle_user(result, email, user)
      return handle_new_user(result, email, user) if user.blank?
      handle_existing_user(result, user)
    end

    def handle_new_user(result, email, user)
      password = generate_user_password
      # Validate the user data
      error = (Constants::BASIC_EMAIL_REGEX !~ email)
      error = validate_user(email, email, password).count > 0 unless error

      if !error
        # Invite new user
        user = invite_new_user(email)

        result[:status] = :user_created
        result[:alert] = :success
        result[:user] = user

        # Invitation to team
        if @team.present?
          user_team = create_user_team_relation_and_notification(user)
          result[:status] = :user_created_invited_to_team
          result[:user_team] = user_team
        end
      else
        # Return invalid status
        result[:status] = :user_invalid
        result[:alert] = :danger
      end
      result
    end

    def handle_existing_user(result, user)
      result[:status] =
        :"#{:user_exists}#{:_unconfirmed unless user.confirmed?}"
      result[:alert] = :info
      result[:user] = user

      # Invitation to team
      if @team.present?
        if UserTeam.exists?(user: user, team: @team)
          user_team = UserTeam.where(user: user, team: @team).first
        end

        if user_team.present?
          result[:status] =
            :"#{:user_exists_and_in_team}#{:_unconfirmed unless user
              .confirmed?}"
        else
          user_team = create_user_team_relation_and_notification(user)
          result[:status] =
            :"#{:user_exists_invited_to_team}#{:_unconfirmed unless user
              .confirmed?}"
        end
        result[:user_team] = user_team
      end
      result
    end

    def invite_new_user(email)
      user = User.invite!(
        full_name: email,
        email: email,
        initials: email.upcase[0..1],
        skip_invitation: true
      )
      user.update(invited_by: @user)

      # Sending email invitation is done in background job to prevent
      # issues with email delivery. Also invite method must be call
      # with :skip_invitation attribute set to true - see above.
      user.delay.deliver_invitation
      user
    end

    def create_user_team_relation_and_notification(user)
      user_team = UserTeam.new(
        user: user,
        team: @team,
        role: @role
      )
      user_team.save

      generate_notification(
        @user,
        user,
        user_team.team,
        user_team.role_str
      )
      user_team
    end
  end

  CustomInvitationsError = Class.new(StandardError)
end
