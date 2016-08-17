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
      :can_delete_reports,
      :can_create_experiment
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
      :can_view_module_protocols,
      :can_load_protocol_into_module,
      :can_export_protocol_from_module,
      :can_copy_protocol_to_repository,
      :can_view_module_activities,
      :can_view_module_comments,
      :can_add_comment_to_module,
      :can_view_module_samples,
      :can_view_module_archive,
      :can_view_results_in_module,
      :can_view_or_download_result_assets,
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
        if my_module.active? &&
           my_module.experiment.active? &&
           my_module.experiment.project.active?
          proxy.call(*args, &block)
        else
          false
        end
      else
        false
      end
    end

    # ---- Some things are disabled for archived experiment ----
    around [
      :can_edit_experiment,
      :can_view_experiment,
      :can_view_experiment_archive,
      :can_archive_experiment,
      :can_view_experiment_samples,
      :can_clone_experiment,
      :can_move_experiment,
      :can_edit_canvas,
      :can_reposition_modules,
      :can_edit_connections,
      :can_create_modules,
      :can_edit_modules,
      :can_edit_module_groups,
      :can_clone_modules,
      :can_archive_modules
    ] do |proxy, *args, &block|
      if args[0]
        experiment = args[0]
        if experiment.active? &&
           experiment.project.active?
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
    project.archived? && is_owner_of_project(project)
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

  # ---- EXPERIMENT PERMISSIONS ----

  def can_create_experiment(project)
    is_user_or_higher_of_project(project)
  end

  def can_edit_experiment(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  def can_view_experiment(experiment)
    can_view_project(experiment.project)
  end

  def can_view_experiment_archive(experiment)
    can_view_project(experiment.project)
  end

  def can_archive_experiment(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  def can_restore_experiment(experiment)
    experiment.archived? && is_user_or_higher_of_project(experiment.project)
  end

  def can_view_experiment_samples(experiment)
    can_view_samples(experiment.project.organization)
  end

  def can_clone_experiment(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  def can_move_experiment(experiment)
    is_user_or_higher_of_project(experiment.project)
  end
  # ---- WORKFLOW PERMISSIONS ----

  def can_edit_canvas(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  def can_reposition_modules(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  def can_edit_connections(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  # ---- MODULE PERMISSIONS ----

  def can_create_modules(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  def can_edit_modules(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  def can_edit_module_groups(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  def can_clone_modules(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  def can_archive_modules(experiment)
    is_user_or_higher_of_project(experiment.project)
  end

  def can_view_module(my_module)
    can_view_project(my_module.experiment.project)
  end

  def can_edit_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_archive_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_restore_module(my_module)
    my_module.archived? &&
      is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_edit_tags_for_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_add_tag_to_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_remove_tag_from_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_view_module_info(my_module)
    can_view_project(my_module.experiment.project)
  end

  def can_view_module_users(my_module)
    can_view_project(my_module.experiment.project)
  end

  def can_edit_users_on_module(my_module)
    is_owner_of_project(my_module.experiment.project)
  end

  def can_add_user_to_module(my_module)
    is_owner_of_project(my_module.experiment.project)
  end

  def can_remove_user_from_module(my_module)
    is_owner_of_project(my_module.experiment.project)
  end

  def can_view_module_protocols(my_module)
    can_view_module(my_module)
  end

  def can_view_module_activities(my_module)
    is_member_of_project(my_module.experiment.project)
  end

  def can_view_module_comments(my_module)
    can_view_project(my_module.experiment.project)
  end

  def can_add_comment_to_module(my_module)
    is_technician_or_higher_of_project(my_module.experiment.project)
  end

  def can_view_module_samples(my_module)
    can_view_module(my_module) and
    can_view_samples(my_module.experiment.project.organization)
  end

  def can_view_module_archive(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  # ---- RESULTS PERMISSIONS ----

  def can_view_results_in_module(my_module)
    can_view_project(my_module.experiment.project)
  end

  def can_view_or_download_result_assets(my_module)
    is_member_of_project(my_module.experiment.project) || can_view_project(my_module.experiment.project)
  end

  def can_view_result_comments(my_module)
    can_view_project(my_module.experiment.project)
  end

  def can_add_result_comment_in_module(my_module)
    is_technician_or_higher_of_project(my_module.experiment.project)
  end

  # ---- RESULT TEXT PERMISSIONS ----

  def can_create_result_text_in_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_edit_result_text_in_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_archive_result_text_in_module(my_module)
    is_owner_of_project(my_module.experiment.project)
  end

  # ---- RESULT TABLE PERMISSIONS ----

  def can_create_result_table_in_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_edit_result_table_in_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_archive_result_table_in_module(my_module)
    is_owner_of_project(my_module.experiment.project)
  end

  # ---- RESULT ASSET PERMISSIONS ----

  def can_create_result_asset_in_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_edit_result_asset_in_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_archive_result_asset_in_module(my_module)
    is_owner_of_project(my_module.experiment.project)
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
    is_technician_or_higher_of_project(my_module.experiment.project)
  end

  def can_delete_samples_from_module(my_module)
    is_technician_or_higher_of_project(my_module.experiment.project)
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

  # ---- PROTOCOL PERMISSIONS ----

  def can_view_organization_protocols(organization)
    is_member_of_organization(organization)
  end

  def can_create_new_protocol(organization)
    is_normal_user_or_admin_of_organization(organization)
  end

  def can_import_protocols(organization)
    is_normal_user_or_admin_of_organization(organization)
  end

  def can_view_protocol(protocol)
    if protocol.in_repository_public?
      is_member_of_organization(protocol.organization)
    elsif (protocol.in_repository_private? or protocol.in_repository_archived?)
      is_member_of_organization(protocol.organization) and
      protocol.added_by == current_user
    elsif protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      can_view_module(my_module) &&
      my_module.experiment.active?
    else
      false
    end
  end

  def can_edit_protocol(protocol)
    is_normal_user_or_admin_of_organization(protocol.organization) and
    current_user == protocol.added_by and (not protocol.in_repository_archived?)
  end

  def can_clone_protocol(protocol)
    is_normal_user_or_admin_of_organization(protocol.organization) and
    (
      protocol.in_repository_public? or
      (protocol.in_repository_private? and current_user == protocol.added_by)
    )
  end

  def can_make_protocol_private(protocol)
    protocol.added_by == current_user and
    protocol.in_repository_public?
  end

  def can_publish_protocol(protocol)
    protocol.added_by == current_user and
    protocol.in_repository_private?
  end

  def can_export_protocol(protocol)
    (protocol.in_repository_public? and is_member_of_organization(protocol.organization)) or
    (protocol.in_repository_private? and protocol.added_by == current_user) or
    (protocol.in_module? and can_export_protocol_from_module(protocol.my_module))
  end

  def can_archive_protocol(protocol)
    protocol.added_by == current_user and
    (protocol.in_repository_public? or protocol.in_repository_private?)
  end

  def can_restore_protocol(protocol)
    protocol.added_by == current_user and
    protocol.in_repository_archived?
  end

  def can_unlink_protocol(protocol)
    if protocol.linked?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.project.active? &&
      is_user_or_higher_of_project(my_module.project) &&
      my_module.experiment.active?
    else
      false
    end
  end

  def can_revert_protocol(protocol)
    if protocol.linked?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      is_user_or_higher_of_project(my_module.experiment.project) &&
      my_module.experiment.active?
    else
      false
    end
  end

  def can_update_protocol_from_parent(protocol)
    if protocol.linked?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      is_user_or_higher_of_project(my_module.experiment.project) &&
      my_module.experiment.active?
    else
      false
    end
  end

  def can_load_protocol_from_repository(protocol, source)
    if can_view_protocol(source)
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      is_user_or_higher_of_project(my_module.experiment.project) &&
      my_module.experiment.active?
    else
      false
    end
  end

  def can_update_parent_protocol(protocol)
    if protocol.linked?
      my_module = protocol.my_module
      parent = protocol.parent

      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      is_normal_user_or_admin_of_organization(parent.organization) &&
      is_user_or_higher_of_project(my_module.experiment.project) &&
      (parent.in_repository_public? or parent.in_repository_private?) &&
      parent.added_by == current_user
    else
      false
    end
  end

  # ---- STEPS PERMISSIONS ----

  def can_load_protocol_into_module(my_module)
    is_user_or_higher_of_project(my_module.experiment.project)
  end

  def can_export_protocol_from_module(my_module)
    can_view_module_protocols(my_module)
  end

  def can_copy_protocol_to_repository(my_module)
    is_normal_user_or_admin_of_organization(my_module.experiment.project.organization)
  end

  def can_link_copied_protocol_in_repository(protocol)
    can_copy_protocol_to_repository(protocol.my_module) and
    is_user_or_higher_of_project(protocol.my_module.experiment.project)
  end

  def can_view_steps_in_protocol(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      can_view_module(my_module)
    elsif protocol.in_repository?
      protocol.in_repository_active? and can_view_protocol(protocol)
    else
      false
    end
  end

  def can_create_step_in_protocol(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      is_user_or_higher_of_project(my_module.experiment.project)
    elsif protocol.in_repository?
      protocol.in_repository_active? and can_edit_protocol(protocol)
    else
      false
    end
  end

  def can_reorder_step_in_protocol(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      is_user_or_higher_of_project(my_module.experiment.project)
    elsif protocol.in_repository?
      protocol.in_repository_active? and can_edit_protocol(protocol)
    else
      false
    end
  end

  # Could possibly be divided into:
  #   - edit step name/description
  #   - adding checklists
  #   - adding assets
  #   - adding tables
  # but right now we have 1 page to rule them all.
  def can_edit_step_in_protocol(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      is_user_or_higher_of_project(my_module.experiment.project)
    elsif protocol.in_repository?
      protocol.in_repository_active? and can_edit_protocol(protocol)
    else
      false
    end
  end

  def can_delete_step_in_protocol(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      is_owner_of_project(my_module.experiment.project)
    elsif protocol.in_repository?
      protocol.in_repository_active? and can_edit_protocol(protocol)
    else
      false
    end
  end

  def can_view_step_comments(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      can_view_project(my_module.experiment.project)
    else
      # In repository, comments are disabled
      false
    end
  end

  def can_add_step_comment_in_protocol(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      is_technician_or_higher_of_project(my_module.experiment.project)
    else
      # In repository, user cannot complete steps
      false
    end
  end

  def can_view_or_download_step_assets(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      (is_member_of_project(my_module.experiment.project) || can_view_project(my_module.experiment.project))
    elsif protocol.in_repository?
      protocol.in_repository_active? and can_view_protocol(protocol)
    else
      false
    end
  end

  def can_complete_step_in_protocol(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      is_technician_or_higher_of_project(my_module.experiment.project)
    else
      # In repository, user cannot complete steps
      false
    end
  end

  def can_uncomplete_step_in_protocol(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      is_user_or_higher_of_project(my_module.experiment.project)
    else
      # In repository, user cannot complete steps
      false
    end
  end

  def can_check_checkbox(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      is_technician_or_higher_of_project(my_module.experiment.project)
    else
      # In repository, user cannot check checkboxes
      false
    end
  end

  def can_uncheck_checkbox(protocol)
    if protocol.in_module?
      my_module = protocol.my_module
      my_module.active? &&
      my_module.experiment.project.active? &&
      my_module.experiment.active? &&
      is_user_or_higher_of_project(my_module.experiment.project)
    else
      # In repository, user cannot check checkboxes
      false
    end
  end

end
