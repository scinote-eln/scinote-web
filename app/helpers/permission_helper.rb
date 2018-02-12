require "aspector"

module PermissionHelper

  #######################################################
  # SOME REFLECTION MAGIC
  #######################################################
  aspector do
    # ---- TEAM ROLES DEFINITIONS ----
    around [
      :is_member_of_team,
      :is_admin_of_team,
      :is_normal_user_of_team,
      :is_normal_user_or_admin_of_team,
      :is_guest_of_team
    ] do |proxy, *args, &block|
      if args[0]
        @user_team = current_user.user_teams.where(team: args[0]).take
        @user_team ? proxy.call(*args, &block) : false
      else
        false
      end
    end

    # ---- PROJECT ROLES DEFINITIONS ----
    around [
      :is_member_of_project,
      :is_owner_of_project,
      :is_user_of_project,
      :is_user_or_higher_of_project,
      :is_technician_of_project,
      :is_technician_or_higher_of_project,
      :is_viewer_of_project
    ] do |proxy, *args, &block|
      if args[0]
        @user_project = current_user.user_projects.where(project: args[0]).take
        @user_project ? proxy.call(*args, &block) : false
      else
        false
      end
    end

  end

  private

  #######################################################
  # ROLES
  #######################################################
  # The following code should stay private, and for each
  # permission that's needed throughout application, a
  # public method should be made. That way, we can have
  # all permissions gathered here in one place.

  # ---- TEAM ROLES ----
  def is_member_of_team(team)
    # This is already checked by aspector, so just return true
    true
  end

  def is_admin_of_team(team)
    @user_team.admin?
  end

  def is_normal_user_of_team(team)
    @user_team.normal_user?
  end

  def is_normal_user_or_admin_of_team(team)
    @user_team.normal_user? or @user_team.admin?
  end

  def is_guest_of_team(team)
    @user_team.guest?
  end

  # ---- PROJECT ROLES ----
  def is_member_of_project(project)
    # This is already checked by aspector, so just return true
    true
  end

  def is_creator_of_project(project)
    project.created_by == current_user
  end

  def is_owner_of_project(project)
    @user_project.owner?
  end

  def is_user_of_project(project)
    @user_project.normal_user?
  end

  def is_user_or_higher_of_project(project)
    @user_project.normal_user? or @user_project.owner?
  end

  def is_technician_of_project(project)
    @user_project.technician?
  end

  def is_technician_or_higher_of_project(project)
    @user_project.technician? or
      @user_project.normal_user? or
      @user_project.owner?
  end

  def is_viewer_of_project(project)
    @user_project.viewer?
  end

  public

  #######################################################
  # PERMISSIONS
  #######################################################
  # The following list can be expanded for new permissions,
  # and only the following list should be public. Also,
  # in a lot of cases, the following methods should be added
  # to "is project archived" or "is module archived" checks
  # at the beginning of this file (via aspector).

  # ---- ATWHO PERMISSIONS ----
  # def can_view_team_users(team)
  #   is_member_of_team(team)
  # end

  # ---- PROJECT PERMISSIONS ----

  # def can_view_projects(team)
  #   is_member_of_team(team)
  # end

  # def can_create_project(team)
  #   is_normal_user_or_admin_of_team(team)
  # end

  # ---- REPORTS PERMISSIONS ----

  # ---- SAMPLE PERMISSIONS ----

  # def can_create_samples(team)
  #   is_normal_user_or_admin_of_team(team)
  # end

  # def can_view_samples(team)
  #   is_member_of_team(team)
  # end

  # Only person who created the sample
  # or team admin can edit it
  # def can_edit_sample(sample)
  #   is_admin_of_team(sample.team) or
  #     sample.user == current_user
  # end

  # Only person who created sample can delete it
  # def can_delete_sample(sample)
  #   sample.user == current_user
  # end

  # def can_delete_samples(team)
  #   is_normal_user_or_admin_of_team(team)
  # end

  # ---- SAMPLE TYPES PERMISSIONS ----

  # def can_create_sample_type_in_team(team)
  #   is_normal_user_or_admin_of_team(team)
  # end

  # ---- SAMPLE GROUPS PERMISSIONS ----

  # def can_create_sample_group_in_team(team)
  #   is_normal_user_or_admin_of_team(team)
  # end

  # ---- CUSTOM FIELDS PERMISSIONS ----

  # def can_create_custom_field_in_team(team)
  #   is_normal_user_or_admin_of_team(team)
  # end

  # def can_edit_custom_field(custom_field)
  #   custom_field.user == current_user ||
  #     is_admin_of_team(custom_field.team)
  # end

  # def can_delete_custom_field(custom_field)
  #   custom_field.user == current_user ||
  #     is_admin_of_team(custom_field.team)
  # end

  # ---- PROTOCOL PERMISSIONS ----

  # def can_view_team_protocols(team)
  #   is_member_of_team(team)
  # end

  # def can_create_new_protocol(team)
  #   is_normal_user_or_admin_of_team(team)
  # end

  # def can_import_protocols(team)
  #   is_normal_user_or_admin_of_team(team)
  # end

  # def can_edit_protocol(protocol)
  #   is_normal_user_or_admin_of_team(protocol.team) and
  #   current_user == protocol.added_by and (not protocol.in_repository_archived?)
  # end

  # def can_clone_protocol(protocol)
  #   is_normal_user_or_admin_of_team(protocol.team) and
  #   (
  #     protocol.in_repository_public? or
  #     (protocol.in_repository_private? and current_user == protocol.added_by)
  #   )
  # end

  # def can_make_protocol_private(protocol)
  #   protocol.added_by == current_user and
  #   protocol.in_repository_public?
  # end

  # def can_publish_protocol(protocol)
  #   protocol.added_by == current_user and
  #   protocol.in_repository_private?
  # end

  # def can_archive_protocol(protocol)
  #   protocol.added_by == current_user and
  #     (protocol.in_repository_public? or protocol.in_repository_private?)
  # end

  # def can_restore_protocol(protocol)
  #   protocol.added_by == current_user and
  #     protocol.in_repository_archived?
  # end

  # ---- REPOSITORIES PERMISSIONS ----

  # def can_view_team_repositories(team)
  #   is_member_of_team(team)
  # end

  # def can_create_repository(team)
  #   is_admin_of_team(team) &&
  #     team.repositories.count < Constants::REPOSITORIES_LIMIT
  # end

  # def can_view_repository(repository)
  #   is_member_of_team(repository.team)
  # end

  # def can_edit_and_destroy_repository(repository)
  #   is_admin_of_team(repository.team)
  # end

  # def can_copy_repository(repository)
  #   can_create_repository(repository.team)
  # end

  # def can_create_columns_in_repository(repository)
  #   is_normal_user_or_admin_of_team(repository.team)
  # end

  # def can_delete_column_in_repository(column)
  #   column.created_by == current_user ||
  #     is_admin_of_team(column.repository.team)
  # end

  # def can_edit_column_in_repository(column)
  #   column.created_by == current_user ||
  #     is_admin_of_team(column.repository.team)
  # end

  # def can_create_repository_records(repository)
  #   is_normal_user_or_admin_of_team(repository.team)
  # end

  # def can_import_repository_records(repository)
  #   is_normal_user_or_admin_of_team(repository.team)
  # end

  # def can_edit_repository_record(record)
  #   is_normal_user_or_admin_of_team(record.repository.team)
  # end

  # def can_delete_repository_records(repository)
  #   is_normal_user_or_admin_of_team(repository.team)
  # end

  # def can_delete_repository_record(record)
  #   team = record.repository.team
  #   is_admin_of_team(team) || (is_normal_user_of_team(team) &&
  #                              record.created_by == current_user)
  # end
end
