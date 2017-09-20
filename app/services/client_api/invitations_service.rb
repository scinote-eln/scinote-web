module ClientApi
  class InvitationsService
    include InputSanitizeHelper
    include UsersGenerator

    def initialize(args)
      @user = args[:user]
      @emails = args[:emails].map(&:downcase)
      @team = args[:team]
      @role = args[:role]

      raise ClientApi::CustomInvitationsError unless @emails && @team && @role
      @emails && @emails.empty? { raise ClientApi::CustomInvitationsError }
      @role && !UserTeam.roles.keys.include?(@role) { raise ClientApi::CustomInvitationsError }
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

        # User does not exist
        if user.blank?
          password = generate_user_password
          # Validate the user data
          error = !(Constants::BASIC_EMAIL_REGEX === email)
          error = validate_user(email, email, password).count > 0 unless error

          if !error
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
        # User exists
        else
          result[:status] = :"#{:user_exists}#{:_unconfirmed if !user.confirmed?}"
          result[:alert] = :info
          result[:user] = user

          # Invitation to team
          if @team.present?
            user_team =
              UserTeam.where(user: user, team: @team).first if UserTeam.exists?(user: user, team: @team)
            
            if user_team.present?
              result[:status] = :"#{:user_exists_and_in_team}#{:_unconfirmed if !user.confirmed?}"

            else
              user_team = create_user_team_relation_and_notification(user)
              result[:status] = :"#{:user_exists_invited_to_team}#{:_unconfirmed if !user.confirmed?}"
            end
            result[:user_team] = user_team
          end
        end
        invite_results << result
      end
      invite_results
    end

    private

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
        user_team.role_str,
        user_team.team
      )
      user_team
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
  end

  CustomInvitationsError = Class.new(StandardError)
end