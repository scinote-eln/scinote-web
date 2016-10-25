class Users::SettingsController < ApplicationController
  include UsersGenerator

  before_action :load_user, only: [
    :preferences,
    :update_preferences,
    :organizations,
    :organization,
    :create_organization,
    :organization_users_datatable,
    :tutorial,
    :reset_tutorial,
    :notifications_settings,
    :user_current_organization,
    :destroy_user_organization
  ]

  before_action :check_organization_permission, only: [
    :organization,
    :update_organization,
    :destroy_organization,
    :organization_name,
    :organization_description,
    :search_organization_users,
    :organization_users_datatable,
    :create_user_and_user_organization
  ]

  before_action :check_create_user_organization_permission, only: [
    :create_user_organization
  ]

  before_action :check_user_organization_permission, only: [
    :update_user_organization,
    :leave_user_organization_html,
    :destroy_user_organization_html,
    :destroy_user_organization
  ]

  def preferences
  end

  def update_preferences
    respond_to do |format|
      if @user.update(update_preferences_params)
        flash[:notice] = t("users.settings.preferences.update_flash")
        format.json {
          flash.keep
          render json: { status: :ok }
        }
      else
        format.json {
          render json: @user.errors,
          status: :unprocessable_entity
        }
      end
    end
  end

  def organizations
    @user_orgs =
      @user
      .user_organizations
      .includes(organization: :users)
      .order(created_at: :asc)
    @member_of = @user_orgs.count
  end

  def organization
    @user_org = UserOrganization.find_by(user: @user, organization: @org)
  end

  def update_organization
    respond_to do |format|
      if @org.update(update_organization_params)
        @org.update(last_modified_by: current_user)
        format.json {
          render json: {
            status: :ok,
            description_label: render_to_string(
              partial: "users/settings/organizations/description_label.html.erb",
              locals: { org: @org }
            )
          }
        }
      else
        format.json {
          render json: @org.errors,
          status: :unprocessable_entity
        }
      end
    end
  end

  def organization_name
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "users/settings/organizations/name_modal_body.html.erb",
            locals: { org: @org }
          })
        }
      }
    end
  end

  def organization_description
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "users/settings/organizations/description_modal_body.html.erb",
            locals: { org: @org }
          })
        }
      }
    end
  end

  def search_organization_users
    respond_to do |format|
      format.json {
        if params.include?(:existing_query) && params[:existing_query].strip
          query = params[:existing_query].strip
          if query.length < Constants::NAME_MIN_LENGTH
            render json: {
              "existing_query": [
                t('general.query.length_too_short',
                  min_length: Constants::NAME_MIN_LENGTH)
              ]
            },
            status: :unprocessable_entity
          elsif query.length > Constants::NAME_MAX_LENGTH
            render json: {
              "existing_query": [
                t('general.query.length_too_long',
                  max_length: Constants::NAME_MAX_LENGTH)
              ]
            },
            status: :unprocessable_entity
          else
            # Okay, query exists and is non-blank, find users
            nr_of_results = User.search(true, query, @org).count


            users = User.search(false, query, @org)
                        .limit(Constants::MODAL_SEARCH_LIMIT)

            nr_of_members = User.organization_search(false, query, @org).count

            render json: {
              html: render_to_string({
                partial: "users/settings/organizations/existing_users_search_results.html.erb",
                locals: {
                  users: users,
                  nr_of_results: nr_of_results,
                  nr_of_members: nr_of_members,
                  org: @org,
                  query: query
                }
              })
            }
          end
        else
          render json: {}, status: :bad_request
        end
      }
    end
  end

  def organization_users_datatable
    respond_to do |format|
      format.json {
        render json: ::OrganizationUsersDatatable.new(view_context, @org, @user)
      }
    end
  end

  def new_organization
    @new_org = Organization.new
  end

  def create_organization
    @new_org = Organization.new(create_organization_params)
    @new_org.created_by = @user

    if @new_org.save
      # Okay, organization is created, now
      # add the current user as admin
      UserOrganization.create(
        user: @user,
        organization: @new_org,
        role: 2
      )

      # Redirect to new organization page
      redirect_to action: :organization, organization_id: @new_org.id
    else
      render :new_organization
    end
  end

  def destroy_organization
    @org.destroy

    flash[:notice] = I18n.t(
      "users.settings.organizations.edit.modal_destroy_organization.flash_success",
      org: @org.name
    )

    # Redirect back to all organizations page
    redirect_to action: :organizations
  end

  def create_user_organization
    @new_user_org = UserOrganization.new(create_user_organization_params)

    # Check if such association doesn't exist already
    if !UserOrganization.where(
      user: @new_user_org.user,
      organization: @new_user_org.organization
      ).exists? && @new_user_org.save

      generate_notification(@user_organization.user,
                            @new_user_org.user,
                            @new_user_org.role_str,
                            @new_user_org.organization)

      flash[:notice] = I18n.t(
        'users.settings.organizations.edit.modal_add_user.existing_flash_success',
        user: @new_user_org.user.full_name,
        role: @new_user_org.role_str
      )
    else
      flash[:alert] =
        I18n.t('users.settings.organizations.edit.modal_add_user.existing_flash_error')
    end

    # Either way, redirect back to organization page
    redirect_to action: :organization,
      organization_id: @new_user_org.organization_id
  end

  def create_user_and_user_organization
    respond_to do |format|
      # User & organization
      # parameters are already taken care of,
      # so only role needs to be verified
      if !params.include? :role or
        !UserOrganization.roles.keys.include? params[:role]
        format.json {
          render json: "Invalid role provided",
          status: :unprocessable_entity
        }
      else
        password = generate_user_password
        user_params = create_user_params
        full_name = user_params[:full_name]
        email = user_params[:email]

        # Validate the user data
        errors = validate_user(full_name, email, password)

        if errors.count == 0
          @user = User.invite!(
            full_name: full_name,
            email: email,
            initials: full_name.split(" ").map{|w| w[0].upcase}.join[0..3],
            skip_invitation: true
          )

          # Sending email invitation is done in background job to prevent
          # issues with email delivery. Also invite method must be call
          # with :skip_invitation attribute set to true - see above.
          @user.delay.deliver_invitation

          # Also generate user organization relation
          @user_org = UserOrganization.new(
            user: @user,
            organization: @org,
            role: params[:role]
          )
          @user_org.save

          # Flash message
          flash[:notice] = t(
            "users.settings.organizations.edit.modal_add_user.new_flash_success",
            user: @user.full_name,
            role: @user_org.role_str,
            email: @user.email
          )
          flash.keep

          # Return success!
          format.json {
            render json: {
              status: :ok
            }
          }
        else
          format.json {
            render json: errors,
            status: :unprocessable_entity
          }
        end
      end
    end
  end

  def update_user_organization
    respond_to do |format|
      if @user_org.update(update_user_organization_params)
        format.json {
          render json: {
            status: :ok
          }
        }
      else
        format.json {
          render json: @user_org.errors,
          status: :unprocessable_entity
        }
      end
    end
  end

  def leave_user_organization_html
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "users/settings/organizations/leave_user_organization_modal_body.html.erb",
            locals: { user_organization: @user_org }
          }),
          heading: I18n.t(
            "users.settings.organizations.index.leave_uo_heading",
            org: @user_org.organization.name
          )
        }
      }
    end
  end

  def destroy_user_organization_html
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "users/settings/organizations/destroy_user_organization_modal_body.html.erb",
            locals: { user_organization: @user_org }
          }),
          heading: I18n.t(
            "users.settings.organizations.edit.destroy_uo_heading",
            user: @user_org.user.full_name,
            org: @user_org.organization.name
          )
        }
      }
    end
  end

  def destroy_user_organization
    respond_to do |format|
      # If user is last administrator of organization,
      # he/she cannot be deleted from it.
      invalid =
        @user_org.admin? &&
        @user_org
        .organization
        .user_organizations
        .where(role: 2)
        .count <= 1

        if !invalid then
          begin
            UserOrganization.transaction do
              # If user leaves on his/her own accord,
              # new owner for projects is the first
              # administrator of organization
              if params[:leave]
                new_owner =
                  @user_org
                  .organization
                  .user_organizations
                  .where(role: 2)
                  .where.not(id: @user_org.id)
                  .first
                  .user
              else
                # Otherwise, the new owner for projects is
                # the current user (= an administrator removing
                # the user from the organization)
                new_owner = current_user
              end
              reset_user_current_organization(@user_org)
              @user_org.destroy(new_owner)
            end
          rescue Exception
            invalid = true
          end
        end

      if !invalid
        if params[:leave] then
          flash[:notice] = I18n.t(
            "users.settings.organizations.index.leave_flash",
            org: @user_org.organization.name
          )
          flash.keep(:notice)
        end

        format.json {
          render json: {
            status: :ok
          }
        }
      else
        format.json {
          render json: @user_org.errors,
          status: :unprocessable_entity
        }
      end
    end
  end

  def tutorial
    @orgs =
      @user
      .user_organizations
      .includes(organization: :users)
      .where(role: 1..2)
      .order(created_at: :asc)
      .map { |uo| uo.organization }
    @member_of = @orgs.count

    respond_to do |format|
      format.json {
        render json: {
          status: :ok,
          html: render_to_string({
            partial: "users/settings/repeat_tutorial_modal_body.html.erb"
          })
        }
      }
    end
  end

  def reset_tutorial
    if @user.update(tutorial_status: 0) && params[:org][:id].present?
      @user.update(current_organization_id: params[:org][:id])
      cookies.delete :tutorial_data
      cookies.delete :current_tutorial_step
      cookies[:repeat_tutorial_org_id] = {
        value: params[:org][:id],
        expires: 1.day.from_now
      }

      flash[:notice] = t("users.settings.preferences.tutorial.tutorial_reset_flash")
      redirect_to root_path
    else
      flash[:alert] = t("users.settings.preferences.tutorial.tutorial_reset_error")
      redirect_to :back
    end
  end

  def notifications_settings
    @user.assignments_notification =
      params[:assignments_notification] ? true : false
    @user.recent_notification = params[:recent_notification] ? true : false
    @user.recent_notification_email =
      params[:recent_notification_email] ? true : false
    @user.assignments_notification_email =
      params[:assignments_notification_email] ? true : false
    @user.system_message_notification_email =
      params[:system_message_notification_email] ? true : false

    if @user.save
      respond_to do |format|
        format.json do
          render json: {
            status: :ok
          }
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            status: :unprocessable_entity
          }
        end
      end
    end
  end

  def user_current_organization
    @user.current_organization_id = params[:user][:current_organization_id]
    @changed_org = Organization.find_by_id(@user.current_organization_id)
    if params[:user][:current_organization_id].present? && @user.save
      flash[:success] = t('users.settings.changed_org_flash',
                          team: @changed_org.name)
      redirect_to root_path
    else
      flash[:alert] = t('users.settings.changed_org_error_flash')
      redirect_to :back
    end
  end

  private

  def load_user
    @user = current_user
  end

  def check_organization_permission
    @org = Organization.find_by_id(params[:organization_id])
    unless is_admin_of_organization(@org)
      render_403
    end
  end

  def check_create_user_organization_permission
    @org = Organization.find_by_id(params[:user_organization][:organization_id])
    unless is_admin_of_organization(@org)
      render_403
    end
  end

  def check_user_organization_permission
    @user_org = UserOrganization.find_by_id(params[:user_organization_id])
    @org = @user_org.organization
    # Don't allow the user to modify UserOrganization-s if he's not admin,
    # unless he/she is modifying his/her UserOrganization
    if current_user != @user_org.user and
      !is_admin_of_organization(@user_org.organization)
      render_403
    end
  end

  def update_preferences_params
    params.require(:user).permit(
      :time_zone
    )
  end

  def create_organization_params
    params.require(:organization).permit(
      :name,
      :description
    )
  end

  def update_organization_params
    params.require(:organization).permit(
      :name,
      :description
    )
  end

  def create_user_params
    params.require(:user).permit(
      :full_name,
      :email
    )
  end

  def create_user_organization_params
    params.require(:user_organization).permit(
      :user_id,
      :organization_id,
      :role
    )
  end

  def update_user_organization_params
    params.require(:user_organization).permit(
      :role
    )
  end

  def generate_notification(user, target_user, role, org)
    title = I18n.t('notifications.assign_user_to_organization',
                   assigned_user: target_user.name,
                   role: role,
                   organization: org.name,
                   assigned_by_user: user.name)

    message = "#{I18n.t('search.index.organization')} #{org.name}"
    notification = Notification.create(
      type_of: :assignment,
      title:
        ActionController::Base.helpers.sanitize(title),
      message:
      ActionController::Base.helpers.sanitize(message),
    )

    if target_user.assignments_notification
      UserNotification.create(notification: notification, user: target_user)
    end
  end

  def reset_user_current_organization(user_org)
    ids = user_org.user.organizations_ids
    ids -= [user_org.organization.id]
    user_org.user.current_organization_id = ids.first
    user_org.user.save
  end
end
