# frozen_string_literal: true

class NotificationExtends
  NOTIFICATIONS_TYPES = {
    designate_user_to_my_module_activity: {
      code: 13,
      recipients_module: :DesignateToMyModuleRecipients
    },
    undesignate_user_from_my_module_activity: {
      code: 14,
      recipients_module: :DesignateToMyModuleRecipients
    },
    my_module_due_date_reminder: {
      recipients_module: :MyModuleDesignatedRecipients
    },
    add_comment_to_module_activity: {
      code: 35,
      recipients_module: :MyModuleDesignatedRecipients
    },
    edit_module_comment_activity: {
      code: 36,
      recipients_module: :MyModuleDesignatedRecipients
    },
    delete_module_comment_activity: {
      code: 37,
      recipients_module: :MyModuleDesignatedRecipients
    },
    add_comment_to_step_activity: {
      code: 17,
      recipients_module: :MyModuleDesignatedRecipients
    },
    edit_step_comment_activity: {
      code: 38,
      recipients_module: :MyModuleDesignatedRecipients
    },
    delete_step_comment_activity: {
      code: 39,
      recipients_module: :MyModuleDesignatedRecipients
    },
    add_comment_to_result_activity: {
      code: 24,
      recipients_module: :MyModuleDesignatedRecipients
    },
    edit_result_comment_activity: {
      code: 40,
      recipients_module: :MyModuleDesignatedRecipients
    },
    delete_result_comment_activity: {
      code: 41,
      recipients_module: :MyModuleDesignatedRecipients
    },
    assign_user_to_project_activity: {
      code: 5,
      recipients_module: :AssignedRecipients
    },
    unassign_user_from_project_activity: {
      code: 7,
      recipients_module: :AssignedRecipients
    },
    project_access_changed_all_team_members_activity: {
      code: 241,
      recipients_module: :AssignedGroupRecipients
    },
    project_grant_access_to_all_team_members_activity: {
      code: 242,
      recipients_module: :AssignedGroupRecipients
    },
    project_remove_access_from_all_team_members_activity: {
      code: 243,
      recipients_module: :AssignedGroupRecipients
    },
    change_user_role_on_project_activity: {
      code: 6,
      recipients_module: :AssignedRecipients
    },
    change_user_role_on_experiment_activity: {
      code: 165,
      recipients_module: :AssignedRecipients
    },
    change_user_role_on_my_module_activity: {
      code: 166,
      recipients_module: :AssignedRecipients
    },
    item_low_stock_reminder: {
      recipients_module: :RepositoryItemRecipients
    },
    item_date_reminder: {
      recipients_module: :RepositoryItemRecipients
    },
    smart_annotation_added: {
      recipients_module: :DirectRecipient
    },
    invite_user_to_team: {
      code: 92,
      recipients_module: :DirectRecipient
    },
    remove_user_from_team: {
      code: 93,
      recipients_module: :DirectRecipient
    },
    change_users_role_on_team_activity: {
      code: 94,
      recipients_module: :UserChangedRecipient
    },
    delivery: {
      recipients_module: :DirectRecipient
    }
  }

  NOTIFICATIONS_GROUPS = {
    my_module: {
      my_module_designation: %I[
        designate_user_to_my_module_activity
        undesignate_user_from_my_module_activity
      ],
      my_module_due_date: %I[
        my_module_due_date_reminder
      ],
      my_module_comments: %I[
        add_comment_to_module_activity
        edit_module_comment_activity
        delete_module_comment_activity
        add_comment_to_step_activity
        edit_step_comment_activity
        delete_step_comment_activity
        add_comment_to_result_activity
        edit_result_comment_activity
        delete_result_comment_activity
      ]
    },
    project_experiment: {
      project_experiment_access: %I[
        assign_user_to_project_activity
        unassign_user_from_project_activity
        project_grant_access_to_all_team_members_activity
        project_remove_access_from_all_team_members_activity
      ],
      project_experiment_role_change: %I[
        change_user_role_on_project_activity
        change_user_role_on_experiment_activity
        change_user_role_on_my_module_activity
        project_access_changed_all_team_members_activity
      ]
    },
    repository: {
      repository_stock: %I[
        item_low_stock_reminder
      ],
      repository_date_reminder: %I[
        item_date_reminder
      ]
    },
    other: {
      other_smart_annotation: %I[
        smart_annotation_added
      ],
      other_team_invitation: %I[
        invite_user_to_team
        remove_user_from_team
        change_users_role_on_team_activity
      ],
      always_on: %I[
        delivery
      ]
    }
  }
end
