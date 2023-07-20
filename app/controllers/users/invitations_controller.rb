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
        if user.errors.blank?
          @team.created_by = user
          @team.save
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
        user = User.find_by(email: email)

        if user
          result[:status] = :user_exists
        else
          user = User.invite!(
            full_name: email,
            email: email,
            initials: email.upcase[0..1],
            skip_invitation: true
          )
          user.update(invited_by: @user)

          result[:status] = :user_created

          # Sending email invitation is done in background job to prevent
          # issues with email delivery. Also invite method must be call
          # with :skip_invitation attribute set to true - see above.
          user.delay.deliver_invitation
        end

        if @teams.any? && user
          @user_role ||= UserRole.find_predefined_normal_user_role
          @teams.each do |team|
            if team.user_assignments.exists?(user: user)
              result[:status] = :user_exists_and_in_team
            else
              # Also generate user team relation
              team.user_assignments.create!(user: user, user_role: @user_role, assigned_by: current_user)

              generate_notification(
                @user,
                user,
                team,
                @user_role.name
              )

              Activities::CreateActivityService
                .call(activity_type: :invite_user_to_team,
                      owner: current_user,
                      subject: team,
                      team: team,
                      message_items: {
                        team: team.id,
                        user_invited: user.id,
                        role: @user_role.name
                      })

              result[:status] = if result[:status] == :user_exists && !user.confirmed?
                                  :user_exists_unconfirmed_invited_to_team
                                elsif result[:status] == :user_exists
                                  :user_exists_invited_to_team
                                else
                                  :user_created_invited_to_team
                                end
            end

            result[:user_role_name] = @user_role.name
            result[:team_name] = team.name
          end
        end

        @invite_results << result
      end

      render json: {
        html: render_to_string(partial: 'shared/invite_users_modal_results', formats: :html)
      }
    end

    def invitable_teams
      teams = current_user.teams
                          .select(:id, :name)
                          .joins(user_assignments: :user_role)
                          .where(user_assignments: { user: current_user })
                          .where('? = ANY(user_roles.permissions)', TeamPermissions::USERS_MANAGE)
                          .distinct
      teams = teams.where_attributes_like('teams.name', params[:query]) if params[:query].present?

      teams = teams.select { |team| can_invite_team_users?(team) }
      render json: teams.map { |t| { value: t.id, label: escape_input(t.name) } }.to_json
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
      @emails = params[:emails]&.map(&:strip)&.map(&:downcase)

      @teams = Team.where(id: params[:team_ids]).select { |team| can_manage_team_users?(team) }
      return render_403 if params[:team_ids].present? && @teams.blank?

      @user_role = UserRole.find_by(id: params[:role_id])

      return render_403 if @emails.blank? # We must have at least one email
    end
  end
end
