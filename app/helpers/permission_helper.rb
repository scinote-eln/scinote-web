require "aspector"

module PermissionHelper

  #######################################################
  # SOME REFLECTION MAGIC
  #######################################################
  aspector do
    # ---- ORGANIZATION ROLES DEFINITIONS ----
    around [
      :is_member_of_organization,
      :is_admin_of_organization,
      :is_normal_user_of_organization,
      :is_normal_user_or_admin_of_organization,
      :is_guest_of_organization
    ] do |proxy, *args, &block|
      if args[0]
        @user_organization = current_user.user_organizations.where(organization: args[0]).take
        @user_organization ? proxy.call(*args, &block) : false
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

    # ---- Almost everything is disabled for archived projects ----
    around [
      :can_view_project,
      :can_view_project_activities,
      :can_view_project_users,
      :can_view_project_notifications,
      :can_view_project_comments,
      :can_edit_project,
      :can_archive_project,
      :can_add_user_to_project,
      :can_remove_user_from_project,
      :can_edit_users_on_project,
      :can_add_comment_to_project,
      :can_restore_archived_modules,
      :can_view_project_samples,
      :can_view_project_archive,
      :can_create_new_tag,
      :can_edit_tag,
      :can_delete_tag,
      :can_edit_canvas,
      :can_reposition_modules,
      :can_edit_connections,
      :can_create_modules,
      :can_edit_modules,
      :can_edit_module_groups,
      :can_clone_modules,
      :can_archive_modules,
      :can_view_reports,
      :can_create_new_report,
      :can_delete_reports
    ] do |proxy, *args, &block|
      if args[0]
        project = args[0]
        project.active? ? proxy.call(*args, &block) : false
      else
        false
      end
    end

    # ---- Almost everything is disabled for archived modules ----
    around [
      :can_view_module,
      # TODO: Because module restoring is made via updating module attributes,
      # (and that action checks if module is editable) this needs to be
      # commented out or that functionality will not work any more.
      #:can_edit_module,
      :can_archive_module,
      :can_edit_tags_for_module,
      :can_add_tag_to_module,
      :can_remove_tag_from_module,
      :can_view_module_info,
      :can_view_module_users,
      :can_edit_users_on_module,
      :can_add_user_to_module,
      :can_remove_user_from_module,
      :can_view_module_activities,
      :can_view_module_comments,
      :can_add_comment_to_module,
      :can_view_module_samples,
      :can_view_module_archive,
      :can_view_steps_in_module,
      :can_create_step_in_module,
      :can_edit_step_in_module,
      :can_delete_step_in_module,
      :can_download_step_assets,
      :can_view_step_comments,
      :can_add_step_comment_in_module,
      :can_complete_step_in_module,
      :can_uncomplete_step_in_module,
      :can_duplicate_step_in_module,
      :can_reorder_step_in_module,
      :can_check_checkbox,
      :can_uncheck_checkbox,
      :can_view_results_in_module,
      :can_download_result_assets,
      :can_view_result_comments,
      :can_add_result_comment_in_module,
      :can_create_result_text_in_module,
      :can_edit_result_text_in_module,
      :can_archive_result_text_in_module,
      :can_create_result_table_in_module,
      :can_edit_result_table_in_module,
      :can_archive_result_table_in_module,
      :can_create_result_asset_in_module,
      :can_edit_result_asset_in_module,
      :can_archive_result_asset_in_module,
      :can_add_samples_to_module,
      :can_delete_samples_from_module
    ] do |proxy, *args, &block|
      if args[0]
        my_module = args[0]
        if my_module.active? and my_module.project.active?
          proxy.call(*args, &block)
        else
          false
        end
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

  # ---- ORGANIZATION ROLES ----
  def is_member_of_organization(organization)
    # This is already checked by aspector, so just return true
    true
  end

  def is_admin_of_organization(organization)
    @user_organization.admin?
  end

  def is_normal_user_of_organization(organization)
    @user_organization.normal_user?
  end

  def is_normal_user_or_admin_of_organization(organization)
    @user_organization.normal_user? or @user_organization.admin?
  end

  def is_guest_of_organization(organization)
    @user_organization.guest?
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

  # ---- PROJECT PERMISSIONS ----

  def can_view_projects(organization)
    is_member_of_organization(organization)
  end

  def can_create_project(organization)
    is_normal_user_or_admin_of_organization(organization)
  end

  # User can view project if he's assigned onto it, or if
  # a project is public/visible, and user is a member of that organization
  def can_view_project(project)
    is_member_of_project(project) or
    (project.visible? and is_member_of_organization(project.organization))
  end

  def can_view_project_activities(project)
    is_member_of_project(project)
  end

  def can_view_project_users(project)
    can_view_project(project)
  end

  def can_view_project_notifications(project)
    can_view_project(project)
  end

  def can_view_project_comments(project)
    can_view_project(project)
  end

  def can_edit_project(project)
    is_owner_of_project(project)
  end

  def can_archive_project(project)
    is_owner_of_project(project)
  end

  def can_restore_project(project)
    project.archived? and is_owner_of_project(project)
  end

  def can_add_user_to_project(project)
    is_owner_of_project(project)
  end

  def can_remove_user_from_project(project)
    is_owner_of_project(project)
  end

  def can_edit_users_on_project(project)
    is_owner_of_project(project)
  end

  def can_add_comment_to_project(project)
    is_technician_or_higher_of_project(project)
  end

  def can_restore_archived_modules(project)
    is_user_or_higher_of_project(project)
  end

  def can_view_project_samples(project)
    can_view_samples(project.organization)
  end

  def can_view_project_archive(project)
    is_user_or_higher_of_project(project)
  end

  def can_create_new_tag(project)
    is_user_or_higher_of_project(project)
  end

  def can_edit_tag(project)
    is_user_or_higher_of_project(project)
  end

  def can_delete_tag(project)
    is_user_or_higher_of_project(project)
  end

  # ---- WORKFLOW PERMISSIONS ----

  def can_edit_canvas(project)
    is_user_or_higher_of_project(project)
  end

  def can_reposition_modules(project)
    is_user_or_higher_of_project(project)
  end

  def can_edit_connections(project)
    is_user_or_higher_of_project(project)
  end

  # ---- MODULE PERMISSIONS ----

  def can_create_modules(project)
    is_user_or_higher_of_project(project)
  end

  def can_edit_modules(project)
    is_user_or_higher_of_project(project)
  end

  def can_edit_module_groups(project)
    is_user_or_higher_of_project(project)
  end

  def can_clone_modules(project)
    is_user_or_higher_of_project(project)
  end

  def can_archive_modules(project)
    is_user_or_higher_of_project(project)
  end

  def can_view_module(my_module)
    can_view_project(my_module.project)
  end

  def can_edit_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_archive_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_restore_module(my_module)
    my_module.archived? and is_user_or_higher_of_project(my_module.project)
  end

  def can_edit_tags_for_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_add_tag_to_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_remove_tag_from_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_view_module_info(my_module)
    can_view_project(my_module.project)
  end

  def can_view_module_users(my_module)
    can_view_project(my_module.project)
  end

  def can_edit_users_on_module(my_module)
    is_owner_of_project(my_module.project)
  end

  def can_add_user_to_module(my_module)
    is_owner_of_project(my_module.project)
  end

  def can_remove_user_from_module(my_module)
    is_owner_of_project(my_module.project)
  end

  def can_view_module_activities(my_module)
    is_member_of_project(my_module.project)
  end

  def can_view_module_comments(my_module)
    can_view_project(my_module.project)
  end

  def can_add_comment_to_module(my_module)
    is_technician_or_higher_of_project(my_module.project)
  end

  def can_view_module_samples(my_module)
    can_view_module(my_module) and
    can_view_samples(my_module.project.organization)
  end

  def can_view_module_archive(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  # ---- STEPS PERMISSIONS ----

  def can_view_steps_in_module(my_module)
    can_view_module(my_module)
  end

  def can_create_step_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  # Could possibly be divided into:
  #   - edit step name/description
  #   - adding checklists
  #   - adding assets
  #   - adding tables
  # but right now we have 1 page to rule them all.
  def can_edit_step_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_delete_step_in_module(my_module)
    is_owner_of_project(my_module.project)
  end

  def can_download_step_assets(my_module)
    is_member_of_project(my_module.project)
  end

  def can_view_step_comments(my_module)
    can_view_project(my_module.project)
  end

  def can_add_step_comment_in_module(my_module)
    is_technician_or_higher_of_project(my_module.project)
  end

  def can_complete_step_in_module(my_module)
    is_technician_or_higher_of_project(my_module.project)
  end

  def can_uncomplete_step_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_duplicate_step_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_reorder_step_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_check_checkbox(my_module)
    is_technician_or_higher_of_project(my_module.project)
  end

  def can_uncheck_checkbox(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  # ---- RESULTS PERMISSIONS ----

  def can_view_results_in_module(my_module)
    can_view_project(my_module.project)
  end

  def can_download_result_assets(my_module)
    is_member_of_project(my_module.project)
  end

  def can_view_result_comments(my_module)
    can_view_project(my_module.project)
  end

  def can_add_result_comment_in_module(my_module)
    is_technician_or_higher_of_project(my_module.project)
  end

  # ---- RESULT TEXT PERMISSIONS ----

  def can_create_result_text_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_edit_result_text_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_archive_result_text_in_module(my_module)
    is_owner_of_project(my_module.project)
  end

  # ---- RESULT TABLE PERMISSIONS ----

  def can_create_result_table_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_edit_result_table_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_archive_result_table_in_module(my_module)
    is_owner_of_project(my_module.project)
  end

  # ---- RESULT ASSET PERMISSIONS ----

  def can_create_result_asset_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_edit_result_asset_in_module(my_module)
    is_user_or_higher_of_project(my_module.project)
  end

  def can_archive_result_asset_in_module(my_module)
    is_owner_of_project(my_module.project)
  end

  # ---- REPORTS PERMISSIONS ----

  def can_view_reports(project)
    can_view_project(project)
  end

  def can_create_new_report(project)
    is_technician_or_higher_of_project(project)
  end

  def can_delete_reports(project)
    is_technician_or_higher_of_project(project)
  end

  # ---- SAMPLE PERMISSIONS ----

  def can_create_samples(organization)
    is_normal_user_or_admin_of_organization(organization)
  end

  def can_view_samples(organization)
    is_member_of_organization(organization)
  end

  # Only person who created the sample
  # or organization admin can edit it
  def can_edit_sample(sample)
    is_admin_of_organization(sample.organization) or
    sample.user == current_user
  end

  # Only person who created sample can delete it
  def can_delete_sample(sample)
    sample.user == current_user
  end

  def can_delete_samples(organization)
    is_normal_user_or_admin_of_organization(organization)
  end

  def can_add_samples_to_module(my_module)
    is_technician_or_higher_of_project(my_module.project)
  end

  def can_delete_samples_from_module(my_module)
    is_technician_or_higher_of_project(my_module.project)
  end

  # ---- SAMPLE TYPES PERMISSIONS ----

  def can_create_sample_type_in_organization(organization)
    is_normal_user_or_admin_of_organization(organization)
  end

  def can_edit_sample_type_in_organization(organization)
    is_normal_user_or_admin_of_organization(organization)
  end

  # ---- SAMPLE GROUPS PERMISSIONS ----

  def can_create_sample_group_in_organization(organization)
    is_normal_user_or_admin_of_organization(organization)
  end

  def can_edit_sample_group_in_organization(organization)
    is_normal_user_or_admin_of_organization(organization)
  end

  # ---- CUSTOM FIELDS PERMISSIONS ----

  def can_create_custom_field_in_organization(organization)
    is_normal_user_or_admin_of_organization(organization)
  end

end
