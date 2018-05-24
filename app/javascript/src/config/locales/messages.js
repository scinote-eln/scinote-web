export default {
  "en-US": {
    general: {
      close: "Close",
      cancel: "Cancel",
      update: "Update",
      edit: "Edit",
      loading: "Loading ...",
      upload: "Upload",
      about_scinote: "About SciNote",
      core_version: "SciNote core version",
      addon_versions: "Addon versions",
      project: "Project",
      task: "Task"
    },
    page_title: {
      root: "SciNote",
      settings_preference_page: "SciNote | Settings | Preferences",
      settings_profile_page: "SciNote | Settings | Profile",
      team_page: "SciNote | Settings | Teams | {name}",
      all_teams_page: "SciNote | Settings | Teams",
      new_team_page: "SciNote | Settings | Teams | New"
    },
    validators: {
      text: {
        text_too_short: "is too short (minimum is {min_length} characters)",
        text_too_long: "is too long (maximum is {max_length} characters)",
        text_blank: "can't be blank",
        invalid_email: "invalid email"
      },
      file: {
        invalid_file_extension: "invalid file extension (valid extensions are {valid_extensions})",
        file_too_large: "file too large (maximum size is {max_size} MB)"
      }
    },
    navbar: {
      page_title: "SciNote",
      home_label: "Home",
      protocols_label: "Protocols",
      repositories_label: "Repositories",
      activities_label: "Activities",
      search_label: "Search",
      notifications_label: "Notifications",
      info_label: "Info"
    },
    invite_users: {
      modal_title: "Invite users to team {team}",
      input_text: "Invite more people to team {team} and start using SciNote.",
      input_help:
        "Input one or multiple emails, confirm each email with ENTER key.",
      dropdown_button: {
        invite: "Invite user/s",
        guest: "as Guest/s",
        normal_user: "as Normal user/s",
        admin: "as Administrator/s"
      },
      results_title: "Invitation results:",
      roles: {
        guest: "Guest",
        normal_user: "Normal user",
        admin: "Administrator"
      },
      results_msg: {
        user_exists: "User is already a member of SciNote.",
        user_exists_unconfirmed:
          "User is already a member of SciNote but is not confirmed yet.",
        user_exists_and_in_team_unconfirmed:
          "User is already a member of SciNote and team {team} as {role} but is not confirmed yet.",
        user_exists_invited_to_team_unconfirmed:
          "User is already a member of SciNote but is not confirmed yet - successfully invited to team {team} as {role}.",
        user_exists_and_in_team:
          "User is already a member of SciNote and team {team} as {role}.",
        user_exists_invited_to_team:
          "User was already a member of SciNote - successfully invited to team {team} as {role}.",
        user_created: "User succesfully invited to SciNote.",
        user_created_invited_to_team:
          "User successfully invited to SciNote and team {team} as {role}.",
        user_invalid: "Invalid email.",
        too_many_emails:
          "Only invited first {nr} emails. To invite more users, fill in another invitation form."
      }
    },
    settings_page: {
      all_teams: "All teams",
      in_team: "You are member of {num} team.",
      in_teams: "You are member of {num} teams.",
      shows_total_entries: "Showing {start} to {to} of {total} entries.",
      leave_team: "Leave team",
      account: "Account",
      success_update_flash: "Your account has been updated successfully",
      team: "Team",
      avatar: "Avatar",
      edit_avatar: "Edit Avatar",
      upload_new_avatar: "Upload new avatar file",
      change: "Change",
      change_password: "Password",
      new_password: "New password",
      password_confirmation:
        "<strong>Current password</strong> <i>(we need your current password to confirm your changes)</i>",
      new_password_confirmation: "New password confirmation",
      email: "Email",
      new_email: "New email",
      initials: "Initials",
      full_name: "Full name",
      my_profile: "My Profile",
      my_statistics: "My Statistics",
      teams: "Teams",
      project: "Project",
      projects: "Projects",
      experiment: "Experiment",
      experiments: "Experiments",
      protocol: "Protocol",
      protocols: "Protocols",
      time_zone: "Time zone",
      time_zone_warning:
        "Time zone setting affects all time & date fields throughout application.",
      notifications: "Notifications",
      profile: "Profile",
      preferences: "Preferences",
      assignement: "Assignement",
      assignement_msg:
        "Assignment notifications appear whenever you get assigned to a team, project, task.",
      recent_changes: "Recent changes",
      recent_changes_msg:
        "Recent changes notifications appear whenever there is a change on a task you are assigned to.",
      system_message: "System message",
      system_message_msg:
        "System message notifications are specifically sent by site maintainers to notify all users about a system update.",
      show_in_scinote: "Show in SciNote",
      notify_me_via_email: "Notify me via email",
      no: "No",
      yes: "Yes",
      leave_team_modal: {
        title: "Leave team {teamName}",
        subtitle:
          "Are you sure you wish to leave team {teamName}? This action is irreversible.",
        warnings: "Leaving team has following consequences:",
        warning_message_one:
          "you will lose access to all content belonging to the team (including projects, tasks, protocols and activities);",
        warning_message_two:
          "all projects in the team where you were the sole <b>Owner</b> will receive a new owner from the team administrators;",
        warning_message_three:
          "all repository protocols in the team belonging to you will be reassigned onto a new owner from team administrators.",
        leave_team: "Leave"
      },
      remove_user_modal: {
        title: "Remove user {user} from team {team}",
        subtitle:
          "Are you sure you wish to remove user {user} from team {team}?",
        warnings: "Removing user from team has following consequences:",
        warning_message_one:
          "user will lose access to all content belonging to the team (including projects, tasks, protocols and activities);",
        warning_message_two:
          "all projects in the team where user was the sole <b>Owner</b> will be reassigned onto you as a new owner;",
        warning_message_three:
          "all repository protocols in the team belonging to user will be reassigned onto you.",
        remove_user: "Remove user"
      },
      update_team_description_modal: {
        title: "Edit team description",
        label: "Description"
      },
      update_team_name_modal: {
        title: "Edit team name",
        label: "Name"
      },
      single_team: {
        created_on: "Created on: <strong>{created_at}</strong>",
        created_by: "Created by: <strong>{created_by}</strong>",
        space_usage: "Space usage: <strong>{space_usage}</strong>",
        no_description: "<i>No description</i>",
        members_panel_title: "Team members",
        add_members: "Add team members",
        actions: {
          user_role: "User role",
          guest: "Guest",
          normal_user: "Normal user",
          administrator: "Administrator",
          remove_user: "Remove"
        }
      },
      new_team: {
        title: "New team",
        name_label: "Team name",
        name_placeholder: "My team",
        name_sublabel:
          "Pick a name that would best describe your team (e.g. 'University of ..., Department of ...').",
        description_label: "Description",
        description_sublabel: "Describe your team.",
        create: "Create team"
      }
    },
    activities: {
      modal_title: "Activities",
      no_data: "No Data",
      more_activities: "More Activities",
      today: "Today"
    },
    global_team_switch: {
      new_team: "New team"
    },
    notifications: {
      dropdown_title: "Notifications",
      dropdown_settings_link: "Settings",
      dropdown_show_all: "Show all notifications"
    },
    info_dropdown: {
      customer_support: "Customer support",
      tutorials: "Tutorials",
      release_notes: "Release notes",
      premium: "Premium",
      contact_us: "Contact us",
      about_scinote: "About SciNote"
    },
    user_account_dropdown: {
      greeting: "Hi, {name}",
      settings: "Settings",
      log_out: "Log out"
    }
  }
};
