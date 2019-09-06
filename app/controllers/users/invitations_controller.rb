# frozen_string_literal: true

module Users
  class InvitationsController < Devise::InvitationsController
    include InputSanitizeHelper
    include UsersGenerator
    include NotificationsHelper

    prepend_before_action :check_captcha, only: [:update]

    prepend_before_action :check_captcha_for_invite, only: [:invite_users]

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

      @emails.each_with_index do |email, email_counter|
        # email_counter starts with 0
        if email_counter >= Constants::INVITE_USERS_LIMIT
          @too_many_emails = true
          break
        end

        result = { email: email }
        unless Constants::BASIC_EMAIL_REGEX.match?(email)
          result[:status] = :user_invalid
          @invite_results << result
          next
        end
        # Check if user already exists
        user = User.find_by_email(email)

        if user
          result[:status] = :user_exists
          result[:user] = user
        else
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
        end

        if @team && user
          user_team = UserTeam.find_by_user_id_and_team_id(user.id, @team.id)
          if user_team
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
              user_team.team,
              user_team.role_str
            )
            Activities::CreateActivityService
              .call(activity_type: :invite_user_to_team,
                    owner: current_user,
                    subject: current_team,
                    team: current_team,
                    message_items: {
                      team: current_team.id,
                      user_invited: user.id,
                      role: user_team.role_str
                    })

            result[:status] = if result[:status] == :user_exists && !user.confirmed?
                                :user_exists_unconfirmed_invited_to_team
                              elsif result[:status] == :user_exists
                                :user_exists_invited_to_team
                              else
                                :user_created_invited_to_team
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

    def check_captcha_for_invite
      if Rails.configuration.x.enable_recaptcha
        unless verify_recaptcha
          render json: { recaptcha_error: t('invite_users.errors.recaptcha') },
                 status: :unprocessable_entity
        end
      end
    end

    def check_invite_users_permission
      @user = current_user
      @emails = params[:emails]&.map(&:downcase)
      @team = Team.find_by_id(params['teamId'])
      @role = params['role']

      return render_403 if @team && @role.nil? # if we select team, we must select role
      return render_403 if @emails.blank? # We must have at least one email
      return render_403 if @team && !can_manage_team_users?(@team) # if we select team, we must check permission
      return render_403 if @role && !UserTeam.roles.key?(@role) # if we select role, we must check that this role exist
    end
  end
end
