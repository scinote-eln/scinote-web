class Users::SettingsController < ApplicationController
  include UsersGenerator
  include NotificationsHelper
  include InputSanitizeHelper

  before_action :load_user, only: [
    :preferences,
    :update_preferences,
    :teams,
    :team,
    :create_team,
    :team_users_datatable,
    :tutorial,
    :reset_tutorial,
    :notifications_settings,
    :user_current_team,
    :destroy_user_team
  ]

  before_action :check_team_permission, only: [
    :team,
    :update_team,
    :destroy_team,
    :team_name,
    :team_description,
    :team_users_datatable
  ]

  before_action :check_user_team_permission, only: [
    :update_user_team,
    :leave_user_team_html,
    :destroy_user_team_html,
    :destroy_user_team
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

  def teams
    @user_teams =
      @user
      .user_teams
      .includes(team: :users)
      .order(created_at: :asc)
    @member_of = @user_teams.count
  end

  def team
    @user_team = UserTeam.find_by(user: @user, team: @team)
  end

  def update_team
    respond_to do |format|
      if @team.update(update_team_params)
        @team.update(last_modified_by: current_user)
        format.json {
          render json: {
            status: :ok,
            description_label: render_to_string(
              partial: "users/settings/teams/description_label.html.erb",
              locals: { team: @team }
            )
          }
        }
      else
        format.json {
          render json: @team.errors,
          status: :unprocessable_entity
        }
      end
    end
  end

  def team_name
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "users/settings/teams/name_modal_body.html.erb",
            locals: { team: @team }
          })
        }
      }
    end
  end

  def team_description
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "users/settings/teams/description_modal_body.html.erb",
            locals: { team: @team }
          })
        }
      }
    end
  end

  def team_users_datatable
    respond_to do |format|
      format.json {
        render json: ::TeamUsersDatatable.new(view_context, @team, @user)
      }
    end
  end

  def new_team
    @new_team = Team.new
  end

  def create_team
    @new_team = Team.new(create_team_params)
    @new_team.created_by = @user

    if @new_team.save
      # Okay, team is created, now
      # add the current user as admin
      UserTeam.create(
        user: @user,
        team: @new_team,
        role: 2
      )

      # Redirect to new team page
      redirect_to action: :team, team_id: @new_team.id
    else
      render :new_team
    end
  end

  def destroy_team
    @team.destroy

    flash[:notice] = I18n.t(
      "users.settings.teams.edit.modal_destroy_team.flash_success",
      team: @team.name
    )

    # Redirect back to all teams page
    redirect_to action: :teams
  end

  def update_user_team
    respond_to do |format|
      if @user_team.update(update_user_team_params)
        format.json {
          render json: {
            status: :ok
          }
        }
      else
        format.json {
          render json: @user_team.errors,
          status: :unprocessable_entity
        }
      end
    end
  end

  def leave_user_team_html
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'users/settings/teams/leave_user_team_modal_body.html.erb',
            locals: { user_team: @user_team }
          ),
          heading: I18n.t(
            'users.settings.teams.index.leave_uo_heading',
            team: escape_input(@user_team.team.name)
          )
        }
      end
    end
  end

  def destroy_user_team_html
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'users/settings/teams/' \
                     'destroy_user_team_modal_body.html.erb',
            locals: { user_team: @user_team }
          ),
          heading: I18n.t(
            'users.settings.teams.edit.destroy_uo_heading',
            user: escape_input(@user_team.user.full_name),
            team: escape_input(@user_team.team.name)
          )
        }
      end
    end
  end

  def destroy_user_team
    respond_to do |format|
      # If user is last administrator of team,
      # he/she cannot be deleted from it.
      invalid =
        @user_team.admin? &&
        @user_team
        .team
        .user_teams
        .where(role: 2)
        .count <= 1

        if !invalid then
          begin
            UserTeam.transaction do
              # If user leaves on his/her own accord,
              # new owner for projects is the first
              # administrator of team
              if params[:leave]
                new_owner =
                  @user_team
                  .team
                  .user_teams
                  .where(role: 2)
                  .where.not(id: @user_team.id)
                  .first
                  .user
              else
                # Otherwise, the new owner for projects is
                # the current user (= an administrator removing
                # the user from the team)
                new_owner = current_user
              end
              reset_user_current_team(@user_team)
              @user_team.destroy(new_owner)
            end
          rescue Exception
            invalid = true
          end
        end

      if !invalid
        if params[:leave] then
          flash[:notice] = I18n.t(
            'users.settings.teams.index.leave_flash',
            team: @user_team.team.name
          )
          flash.keep(:notice)
        end
        generate_notification(@user_team.user,
                              @user_team.user,
                              @user_team.team,
                              false,
                              false)
        format.json {
          render json: {
            status: :ok
          }
        }
      else
        format.json {
          render json: @user_team.errors,
          status: :unprocessable_entity
        }
      end
    end
  end

  def tutorial
    @teams =
      @user
      .user_teams
      .includes(team: :users)
      .where(role: 1..2)
      .order(created_at: :asc)
      .map(&:team)
    @member_of = @teams.count

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
    if @user.update(tutorial_status: 0) && params[:team][:id].present?
      @user.update(current_team_id: params[:team][:id])
      cookies.delete :tutorial_data
      cookies.delete :current_tutorial_step
      cookies[:repeat_tutorial_team_id] = {
        value: params[:team][:id],
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

  def user_current_team
    @user.current_team_id = params[:user][:current_team_id]
    @changed_team = Team.find_by_id(@user.current_team_id)
    if params[:user][:current_team_id].present? && @user.save
      flash[:success] = t('users.settings.changed_team_flash',
                          team: @changed_team.name)
      redirect_to root_path
    else
      flash[:alert] = t('users.settings.changed_team_error_flash')
      redirect_to :back
    end
  end

  private

  def load_user
    @user = current_user
  end

  def check_team_permission
    @team = Team.find_by_id(params[:team_id])
    unless is_admin_of_team(@team)
      render_403
    end
  end

  def check_user_team_permission
    @user_team = UserTeam.find_by_id(params[:user_team_id])
    @team = @user_team.team
    # Don't allow the user to modify UserTeam-s if he's not admin,
    # unless he/she is modifying his/her UserTeam
    if current_user != @user_team.user &&
       !is_admin_of_team(@user_team.team)
      render_403
    end
  end

  def update_preferences_params
    params.require(:user).permit(
      :time_zone
    )
  end

  def create_team_params
    params.require(:team).permit(
      :name,
      :description
    )
  end

  def update_team_params
    params.require(:team).permit(
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

  def update_user_team_params
    params.require(:user_team).permit(
      :role
    )
  end

  def reset_user_current_team(user_team)
    ids = user_team.user.teams_ids
    ids -= [user_team.team.id]
    user_team.user.current_team_id = ids.first
    user_team.user.save
  end
end
