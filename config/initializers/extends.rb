# Extends class holds the arrays for the models enum fields
# so that can be extended in sub modules.

class Extends
  # To extend the enum fields in the engine you have to put in
  # lib/engine_name/engine.rb file as in the example:

  # > initializer 'add_additional enum values to my model' do
  # >   Extends::MY_ARRAY_OF_ENUM_VALUES.merge!(value1, value2, ....)
  # > end
  # >

  # Extends enum types. Should not be freezed, as modules might append to this.
  # !!!Check all addons for the correct order!!!
  # DEPRECATED 'system_message' in (SCI-2952, kept b/c of integer enums)
  NOTIFICATIONS_TYPES = { assignment: 0,
                          recent_changes: 1,
                          system_message: 2, # DEPRECATED
                          deliver: 5 }

  TASKS_STATES = { uncompleted: 0,
                   completed: 1 }

  REPORT_ELEMENT_TYPES = { project_header: 0,
                           my_module: 1,
                           step: 2,
                           result_asset: 3,
                           result_table: 4,
                           result_text: 5,
                           my_module_activity: 6,
                           my_module_samples: 7,
                           step_checklist: 8,
                           step_asset: 9,
                           step_table: 10,
                           step_comments: 11,
                           result_comments: 12,
                           project_activity: 13, # TODO
                           project_samples: 14, # TODO
                           experiment: 15,
                           # Higher number because of addons
                           my_module_repository: 17 }

  # Data type name should match corresponding model's name
  REPOSITORY_DATA_TYPES = { RepositoryTextValue: 0,
                            RepositoryDateValue: 1,
                            RepositoryListValue: 2,
                            RepositoryAssetValue: 3 }

  # Data types which can be imported to repository,
  # name should match record in REPOSITORY_DATA_TYPES
  REPOSITORY_IMPORTABLE_TYPES = %i(RepositoryTextValue RepositoryListValue)

  # Extra attributes used for search in repositories, text columns
  # are only supported
  REPOSITORY_EXTRA_SEARCH_ATTR = ['repository_text_values.data',
                                  'repository_list_items.data',
                                  'assets.file_file_name']

  # Array of includes used in search query for repository rows
  REPOSITORY_SEARCH_INCLUDES = [:repository_text_value,
                                repository_list_value: :repository_list_item,
                                repository_asset_value: :asset]

  # List of implemented core API versions
  API_VERSIONS = ['v1']

  # Array used for injecting names of additional authentication methods for API
  API_PLUGABLE_AUTH_METHODS = [:azure_jwt_auth]

  API_REPOSITORY_DATA_TYPE_MAPPINGS = { 'RepositoryTextValue' => 'text',
                                        'RepositoryDateValue' => 'date',
                                        'RepositoryListValue' => 'list',
                                        'RepositoryAssetValue' => 'file' }

  OMNIAUTH_PROVIDERS = [:linkedin]

  INITIAL_USER_OPTIONS = {}

  # Hash used for mapping file extensions to custom icons,
  # 'extension' => 'path_to_the_icon'
  FILE_ICON_MAPPINGS = {}

  # Hash used for mapping file extensions to custom font awesome icon classes,
  # 'extension' => 'fa class'
  FILE_FA_ICON_MAPPINGS = {}

  ACTIVITY_SUBJECT_TYPES = %w(
    Team Repository Project Experiment MyModule Result Protocol Step
  )

  SEARCHABLE_ACTIVITY_SUBJECT_TYPES = %w(
    Repository Project Experiment MyModule Result Protocol Step
  )

  ACTIVITY_TYPES = {
    create_project: 0,
    rename_project: 1,
    change_project_visibility: 2,
    archive_project: 3,
    restore_project: 4,
    assign_user_to_project: 5,
    change_user_role_on_project: 6,
    unassign_user_from_project: 7,
    create_module: 8,
    clone_module: 9,
    archive_module: 10,
    restore_module: 11,
    change_module_description: 12,
    assign_user_to_module: 13,
    unassign_user_from_module: 14,
    create_step: 15,
    destroy_step: 16,
    add_comment_to_step: 17,
    complete_step: 18,
    uncomplete_step: 19,
    check_step_checklist_item: 20,
    uncheck_step_checklist_item: 21,
    edit_step: 22,
    add_result: 23,
    add_comment_to_result: 24,
    archive_result: 25,
    edit_result: 26,
    create_experiment: 27,
    edit_experiment: 28,
    archive_experiment: 29,
    clone_experiment: 30,
    move_experiment: 31,
    add_comment_to_project: 32,
    edit_project_comment: 33,
    delete_project_comment: 34,
    add_comment_to_module: 35,
    edit_module_comment: 36,
    delete_module_comment: 37,
    edit_step_comment: 38,
    delete_step_comment: 39,
    edit_result_comment: 40,
    delete_result_comment: 41,
    destroy_result: 42,
    start_edit_wopi_file: 43,
    unlock_wopi_file: 44,
    load_protocol_from_file: 45,
    load_protocol_from_repository: 46,
    revert_protocol: 47,
    create_report: 48,
    delete_report: 49,
    edit_report: 50,
    assign_sample: 51,
    unassign_sample: 52,
    complete_task: 53,
    uncomplete_task: 54,
    assign_repository_record: 55,
    unassign_repository_record: 56
  }
end
