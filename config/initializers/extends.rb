# Extends class holds the arrays for the models enum fields
# so that can be extended in sub modules.

# rubocop:disable Style/MutableConstant

class Extends
  # To extend the enum fields in the engine you have to put in
  # lib/engine_name/engine.rb file as in the example:

  # > initializer 'add_additional enum values to my model' do
  # >   Extends::MY_ARRAY_OF_ENUM_VALUES.merge!(value1, value2, ....)
  # > end
  # >

  # Extends enum types. Should not be freezed, as modules might append to this.
  # !!!Check all addons for the correct order!!!
  TASKS_STATES = { uncompleted: 0,
                   completed: 1 }

  REPORT_ELEMENT_TYPES = { project_header: 0,
                           my_module: 1,
                           step: 2,
                           result_asset: 3,
                           result_table: 4,
                           result_text: 5,
                           my_module_activity: 6,
                           my_module_samples: 7, # DEPRECATED in SCI-2228, kept b/c of integer enums
                           step_checklist: 8,
                           step_asset: 9,
                           step_table: 10,
                           step_comments: 11,
                           result_comments: 12,
                           project_activity: 13, # NOT USED, kept b/c of integer enums
                           project_samples: 14, # DEPRECATED in SCI-2228, kept b/c of integer enums
                           experiment: 15,
                           # Higher number because of addons
                           my_module_repository: 17,
                           my_module_protocol: 18 }

  ACTIVE_REPORT_ELEMENTS = %i(project_header my_module experiment my_module_repository)

  # Data type name should match corresponding model's name
  REPOSITORY_DATA_TYPES = { RepositoryTextValue: 0,
                            RepositoryDateValue: 1,
                            RepositoryListValue: 2,
                            RepositoryAssetValue: 3,
                            RepositoryStatusValue: 4,
                            RepositoryDateTimeValue: 5,
                            RepositoryTimeValue: 6,
                            RepositoryDateTimeRangeValue: 7,
                            RepositoryTimeRangeValue: 8,
                            RepositoryDateRangeValue: 9,
                            RepositoryChecklistValue: 10,
                            RepositoryNumberValue: 11,
                            RepositoryStockValue: 12,
                            RepositoryStockConsumptionValue: 13 }

  # Data types which can be imported to repository,
  # name should match record in REPOSITORY_DATA_TYPES
  REPOSITORY_IMPORTABLE_TYPES = %i(RepositoryTextValue RepositoryListValue RepositoryNumberValue
                                   RepositoryDateValue RepositoryDateTimeValue RepositoryTimeValue
                                   RepositoryStatusValue RepositoryChecklistValue RepositoryStockValue)

  REPOSITORY_IMPORT_COLUMN_PRELOADS = %i(repository_list_items repository_status_items repository_checklist_items)

  # Extra attributes used for search in repositories, 'filed_name' => include_hash
  REPOSITORY_EXTRA_SEARCH_ATTR = {
    RepositoryTextValue: {
      field: 'repository_text_values.data', includes: :repository_text_values
    }, RepositoryNumberValue: {
      field: 'repository_number_values.data', includes: :repository_number_values
    }, RepositoryListValue: {
      field: 'repository_list_items.data',
      includes: { repository_list_values: :repository_list_item }
    }, RepositoryChecklistValue: {
      field: 'repository_checklist_items.data',
      includes: { repository_checklist_values: { repository_checklist_items_values: :repository_checklist_item } }
    }, RepositoryStatusValue: {
      field: 'repository_status_items.status',
      includes: { repository_status_values: :repository_status_item }
    }, RepositoryAssetValue: {
      field: 'active_storage_blobs.filename',
      includes: { repository_asset_values: { asset: { file_attachment: :blob } } }
    }
  }

  # Extra attributes used for advanced search in repositories
  REPOSITORY_ADVANCED_SEARCH_ATTR = {
    RepositoryTextValue: {
      table_name: :repository_text_values
    }, RepositoryNumberValue: {
      table_name: :repository_number_values
    }, RepositoryListValue: {
      table_name: :repository_list_values
    }, RepositoryChecklistValue: {
      table_name: :repository_checklist_values
    }, RepositoryStatusValue: {
      table_name: :repository_status_values
    }, RepositoryAssetValue: {
      table_name: :repository_asset_values
    }, RepositoryDateTimeValue: {
      table_name: :repository_date_time_values
    }, RepositoryDateTimeRangeValue: {
      table_name: :repository_date_time_range_values
    }, RepositoryDateValue: {
      table_name: :repository_date_time_values
    }, RepositoryDateRangeValue: {
      table_name: :repository_date_time_range_values
    }, RepositoryTimeValue: {
      table_name: :repository_date_time_values
    }, RepositoryTimeRangeValue: {
      table_name: :repository_date_time_range_values
    }, RepositoryStockValue: {
      table_name: :repository_stock_values
    }
  }

  REPOSITORY_ADVANCED_SEARCH_REFERENCED_VALUE_RELATIONS = {
    RepositoryListValue: 'repository_list_items',
    RepositoryChecklistValue: 'repository_checklist_items',
    RepositoryStatusValue: 'repository_status_items'
  }

  REPOSITORY_ADVANCED_SEARCHABLE_COLUMNS = %i(
    RepositoryTextValue
    RepositoryNumberValue
    RepositoryListValue
    RepositoryChecklistValue
    RepositoryStatusValue
    RepositoryAssetValue
    RepositoryDateTimeValue
    RepositoryDateTimeRangeValue
    RepositoryDateValue
    RepositoryDateRangeValue
    RepositoryTimeValue
    RepositoryTimeRangeValue
    RepositoryStockValue
  )

  STI_PRELOAD_CLASSES = %w(LinkedRepository)

  # Array of preload relations used in search query for repository rows
  REPOSITORY_ROWS_PRELOAD_RELATIONS = []

  # List of implemented core API versions
  API_VERSIONS = ['v1']

  # Array used for injecting names of additional authentication methods for API
  API_PLUGABLE_AUTH_METHODS = [:azure_jwt_auth]

  API_REPOSITORY_DATA_TYPE_MAPPINGS = { 'RepositoryTextValue' => 'text',
                                        'RepositoryDateValue' => 'date',
                                        'RepositoryNumberValue' => 'number',
                                        'RepositoryTimeValue' => 'time',
                                        'RepositoryDateTimeValue' => 'date_time',
                                        'RepositoryDateRangeValue' => 'date_range',
                                        'RepositoryTimeRangeValue' => 'time_range',
                                        'RepositoryDateTimeRangeValue' => 'date_time_range',
                                        'RepositoryListValue' => 'list',
                                        'RepositoryChecklistValue' => 'checklist',
                                        'RepositoryAssetValue' => 'file',
                                        'RepositoryStatusValue' => 'status',
                                        'RepositoryStockValue' => 'stock' }

  OMNIAUTH_PROVIDERS = %i(linkedin customazureactivedirectory okta)

  INITIAL_USER_OPTIONS = {}

  # Hash used for mapping file extensions to custom icons,
  # 'extension' => 'path_to_the_icon'
  FILE_ICON_MAPPINGS = {}

  # Hash used for mapping file extensions to custom font awesome icon classes,
  # 'extension' => 'fa class'
  FILE_FA_ICON_MAPPINGS = {}

  # Mapping of rich text fileds to specific model
  RICH_TEXT_FIELD_MAPPINGS = { 'StepText' => :text,
                               'ResultText' => :text,
                               'Protocol' => :description,
                               'MyModule' => :description }

  DEFAULT_DASHBOARD_CONFIGURATION = [
    { partial: 'dashboards/current_tasks', visible: true, size: 'large-widget', position: 1 },
    { partial: 'dashboards/calendar', visible: true, size: 'small-widget', position: 2 },
    { partial: 'dashboards/recent_work', visible: true, size: 'medium-widget', position: 3 }
  ]

  ACTIVITY_SUBJECT_TYPES = %w(
    Team RepositoryBase Project Experiment MyModule Result Protocol Report RepositoryRow
    ProjectFolder Asset Step LabelTemplate
  ).freeze

  SEARCHABLE_ACTIVITY_SUBJECT_TYPES = %w(
    RepositoryBase RepositoryRow Project Experiment MyModule Result Protocol Step Report
  ).freeze

  ACTIVITY_SUBJECT_CHILDREN = {
    repository_base: [:repository_rows],
    repository_row: nil,
    report: nil,
    team: [:projects],
    project: [:experiments],
    experiment: [:my_modules],
    my_module: %i(results protocols),
    result: [:assets],
    protocol: [:steps],
    step: [:assets]
  }

  ACTIVITY_MESSAGE_ITEMS_TYPES =
    ACTIVITY_SUBJECT_TYPES + %w(
      User Tag RepositoryColumn RepositoryRow Step Result Asset TinyMceAsset
      Repository MyModuleStatus RepositorySnapshot
    ).freeze

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
    designate_user_to_my_module: 13,
    undesignate_user_from_my_module: 14,
    create_step: 15,
    destroy_step: 16,
    add_comment_to_step: 17,
    complete_step: 18,
    uncomplete_step: 19,
    check_step_checklist_item: 20,
    uncheck_step_checklist_item: 21,
    edit_step: 22,
    add_result_old: 23,
    add_comment_to_result: 24,
    archive_result_old: 25,
    edit_result_old: 26,
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
    destroy_result_old: 42,
    start_edit_wopi_file: 43, # not in use
    unlock_wopi_file: 44, # not in use
    load_protocol_to_task_from_file: 45,
    load_protocol_to_task_from_repository: 46,
    update_protocol_in_task_from_repository: 47,
    create_report: 48,
    delete_report: 49,
    edit_report: 50,
    assign_sample: 51, # not in use
    unassign_sample: 52, # not in use
    complete_task: 53,
    uncomplete_task: 54,
    assign_repository_record: 55,
    unassign_repository_record: 56,
    restore_experiment: 57,
    rename_task: 58,
    move_task: 59,
    set_task_due_date: 61,
    change_task_due_date: 62,
    remove_task_due_date: 63,
    add_task_tag: 64,
    edit_tag: 65,
    remove_task_tag: 66, # 67, 68, 69 are in addons
    create_inventory: 70,
    rename_inventory: 71,
    delete_inventory: 72,
    create_item_inventory: 73,
    edit_item_inventory: 74,
    delete_item_inventory: 75,
    create_column_inventory: 76,
    edit_column_inventory: 77,
    delete_column_inventory: 78,
    update_protocol_in_repository_from_task: 79,
    create_protocol_in_repository: 80,
    add_step_to_protocol_repository: 81,
    edit_step_in_protocol_repository: 82,
    delete_step_in_protocol_repository: 83,
    edit_description_in_protocol_repository: 84,
    edit_keywords_in_protocol_repository: 85,
    edit_authors_in_protocol_repository: 86,
    archive_protocol_in_repository: 87,
    restore_protocol_in_repository: 88,
    move_protocol_in_repository: 89,
    import_protocol_in_repository: 90,
    export_protocol_in_repository: 91,
    invite_user_to_team: 92,
    remove_user_from_team: 93,
    change_users_role_on_team: 94,
    export_projects: 95,
    export_inventory_items: 96, # 97 is in addon
    edit_wopi_file_on_result: 99,
    edit_wopi_file_on_step: 100,
    edit_wopi_file_on_step_in_repository: 101,
    copy_inventory_item: 102,
    copy_protocol_in_repository: 103,
    user_leave_team: 104,
    copy_inventory: 105,
    export_protocol_from_task: 106,
    import_inventory_items: 107,
    create_tag: 108,
    delete_tag: 109,
    edit_image_on_result: 110,
    edit_image_on_step: 111,
    edit_image_on_step_in_repository: 112,
    share_inventory: 113,
    unshare_inventory: 114,
    edit_chemical_structure_on_step: 115,
    edit_chemical_structure_on_result: 116,
    edit_chemical_structure_on_step_in_repository: 117,
    edit_chemical_structure_on_task_protocol: 118,
    edit_chemical_structure_on_protocol: 119,
    edit_chemical_structure_on_task: 120,
    create_chemical_structure_on_step: 121,
    create_chemical_structure_on_result: 122,
    create_chemical_structure_on_step_in_repository: 123,
    create_chemical_structure_on_task_protocol: 124,
    create_chemical_structure_on_protocol: 125,
    create_chemical_structure_on_task: 126,
    delete_chemical_structure_on_step: 127,
    delete_chemical_structure_on_result: 128,
    delete_chemical_structure_on_step_in_repository: 129,
    delete_chemical_structure_on_task_protocol: 130,
    delete_chemical_structure_on_protocol: 131,
    delete_chemical_structure_on_task: 132,
    update_share_inventory: 133,
    share_inventory_with_all: 134,
    unshare_inventory_with_all: 135,
    update_share_with_all_permission_level: 136,
    protocol_description_in_task_edited: 137,
    set_task_start_date: 138,
    change_task_start_date: 139,
    remove_task_start_date: 140,
    rename_experiment: 141,
    archive_inventory_item: 142,
    restore_inventory_item: 143,
    archive_inventory: 144,
    restore_inventory: 145,
    export_inventory_items_assigned_to_task: 146,
    export_inventory_snapshot_items_assigned_to_task: 147,
    change_status_on_task_flow: 148, # 149..157 in AdddOn!
    move_project: 158,
    create_project_folder: 159,
    move_project_folder: 160,
    rename_project_folder: 161,
    delete_project_folder: 162,
    generate_pdf_report: 163,
    generate_docx_report: 164,
    change_user_role_on_experiment: 165,
    change_user_role_on_my_module: 166,
    edit_molecule_on_step: 168,
    edit_molecule_on_result: 169,
    edit_molecule_on_step_in_repository: 170,
    create_molecule_on_step: 171,
    create_molecule_on_result: 172,
    create_molecule_on_step_in_repository: 173,
    register_molecule_on_step: 177,
    register_molecule_on_result: 178,
    register_molecule_on_step_in_repository: 179,
    inventory_item_stock_set: 180,
    inventory_item_stock_add: 181,
    inventory_item_stock_remove: 182,
    task_inventory_item_stock_consumed: 183,
    task_steps_rearranged: 184,
    task_step_content_rearranged: 185,
    protocol_steps_rearranged: 186,
    protocol_step_content_rearranged: 187,
    task_step_file_added: 188,
    task_step_file_deleted: 189,
    protocol_step_file_added: 190,
    protocol_step_file_deleted: 191,
    task_step_text_added: 192,
    task_step_text_edited: 193,
    task_step_text_deleted: 194,
    task_step_table_added: 195,
    task_step_table_edited: 196,
    task_step_table_deleted: 197,
    task_step_checklist_added: 198,
    task_step_checklist_edited: 199,
    task_step_checklist_deleted: 200,
    task_step_checklist_item_added: 201,
    task_step_checklist_item_edited: 202,
    task_step_checklist_item_deleted: 203,
    protocol_step_text_added: 204,
    protocol_step_text_edited: 205,
    protocol_step_text_deleted: 206,
    protocol_step_table_added: 207,
    protocol_step_table_edited: 208,
    protocol_step_table_deleted: 209,
    protocol_step_checklist_added: 210,
    protocol_step_checklist_edited: 211,
    protocol_step_checklist_deleted: 212,
    protocol_step_checklist_item_added: 213,
    protocol_step_checklist_item_edited: 214,
    protocol_step_checklist_item_deleted: 215,
    label_template_created: 216,
    label_template_edited: 217,
    label_template_deleted: 218,
    label_template_copied: 219,
    edit_protocol_name_in_repository: 220,
    protocol_name_in_task_edited: 221,
    task_step_duplicated: 222,
    protocol_step_duplicated: 223,
    task_step_text_duplicated: 224,
    task_step_table_duplicated: 225,
    task_step_checklist_duplicated: 226,
    protocol_step_text_duplicated: 227,
    protocol_step_table_duplicated: 228,
    protocol_step_checklist_duplicated: 229,
    protocol_template_published: 230,
    protocol_template_revision_notes_updated: 231,
    protocol_template_draft_deleted: 232,
    protocol_template_access_granted: 233,
    protocol_template_access_changed: 234,
    protocol_template_access_revoked: 235,
    task_protocol_save_to_template: 236,
    protocol_template_draft_created: 237,
    protocol_template_access_granted_all_team_members: 238,
    protocol_template_access_changed_all_team_members: 239,
    protocol_template_access_revoked_all_team_members: 240,
    project_access_changed_all_team_members: 241,
    project_grant_access_to_all_team_members: 242,
    project_remove_access_from_all_team_members: 243,
    team_sharing_tasks_enabled: 244,
    team_sharing_tasks_disabled: 245,
    task_link_sharing_enabled: 246,
    task_link_sharing_disabled: 247,
    shared_task_message_edited: 248,
    task_sequence_asset_added: 249,
    task_sequence_asset_edit_started: 250,
    task_sequence_asset_edit_finished: 251,
    task_sequence_asset_deleted: 252,
    protocol_sequence_asset_added: 253,
    protocol_sequence_asset_edit_started: 254,
    protocol_sequence_asset_edit_finished: 255,
    protocol_sequence_asset_deleted: 256,
    result_content_rearranged: 257,
    add_result: 258,
    edit_result: 259,
    archive_result: 260,
    destroy_result: 261,
    result_table_added: 262,
    result_file_added: 263,
    result_file_deleted: 264,
    result_text_added: 265,
    result_text_edited: 266,
    result_text_deleted: 267,
    result_table_edited: 268,
    result_table_deleted: 269,
    result_duplicated: 270,
    result_text_duplicated: 271,
    result_table_duplicated: 272,
    result_restored: 273,
    task_step_file_moved: 274,
    task_step_text_moved: 275,
    task_step_table_moved: 276,
    task_step_checklist_moved: 277,
    move_chemical_structure_on_step: 278,
    protocol_step_file_moved: 279,
    protocol_step_text_moved: 280,
    protocol_step_table_moved: 281,
    protocol_step_checklist_moved: 282,
    move_chemical_structure_on_step_in_repository: 283,
    result_file_moved: 284,
    result_text_moved: 285,
    result_table_moved: 286,
    sequence_on_result_added: 287,
    sequence_on_result_edited: 288,
    sequence_on_result_deleted: 289,
    sequence_on_result_moved: 290,
    move_chemical_structure_on_result: 291,
    edit_item_field_inventory: 292,
    export_inventories: 293,
    edit_image_on_inventory_item: 294,
    edit_wopi_file_on_inventory_item: 295,
    export_inventory_stock_consumption: 296
  }

  ACTIVITY_GROUPS = {
    projects: [*0..7, 32, 33, 34, 95, 108, 65, 109, *158..162, 241, 242, 243],
    task_results: [23, 26, 25, 42, 24, 40, 41, 99, 110, 122, 116, 128, 169, 172, 178, *246..248, *257..273, *284..291],
    task: [8, 58, 9, 59, *10..14, 35, 36, 37, 53, 54, *60..63, 138, 139, 140, 64, 66, 106, 126, 120, 132,
           148, 166],
    task_protocol: [15, 22, 16, 18, 19, 20, 21, 17, 38, 39, 100, 111, 45, 46, 47, 121, 124, 115, 118, 127, 130, 137,
                    168, 171, 177, 184, 185, 188, 189, *192..203, 221, 222, 224, 225, 226, 236, *249..252, *274..278],
    task_inventory: [55, 56, 146, 147, 183],
    experiment: [*27..31, 57, 141, 165],
    reports: [48, 50, 49, 163, 164],
    inventories: [70, 71, 105, 144, 145, 72, 73, 74, 102, 142, 143, 75, 76, 77,
                  78, 96, 107, 113, 114, *133..136, 180, 181, 182, *292..296],
    protocol_repository: [80, 103, 89, 87, 79, 90, 91, 88, 85, 86, 84, 81, 82,
                          83, 101, 112, 123, 125, 117, 119, 129, 131, 170, 173, 179, 187, 186,
                          190, 191, *204..215, 220, 223, 227, 228, 229, *230..235,
                          *237..240, *253..256, *279..283],
    team: [92, 94, 93, 97, 104, 244, 245],
    label_templates: [*216..219]
  }

  TOP_LEVEL_ASSIGNABLES = %w(Project Team Protocol Repository).freeze

  SHARED_INVENTORIES_PERMISSION_LEVELS = {
    not_shared: 0,
    shared_read: 1,
    shared_write: 2
  }.freeze

  SHARED_OBJECTS_PERMISSION_LEVELS = {
    not_shared: 0,
    shared_read: 1,
    shared_write: 2
  }.freeze

  SHARED_INVENTORIES_PL_MAPPINGS = {
    shared_read: 'view-only',
    shared_write: 'edit'
  }.freeze

  DASHBOARD_BLACKLIST_ACTIVITY_TYPES = %i(export_protocol_in_repository copy_protocol_in_repository).freeze

  DEFAULT_FLOW_NAME = 'SciNote Free default task flow'

  DEFAULT_FLOW_STATUSES = [
    { name: 'Not started', color: '#FFFFFF' },
    { name: 'In progress', color: '#3070ED', consequences: ['MyModuleStatusConsequences::Uncompletion'] },
    { name: 'Completed', color: '#5EC66F', consequences: ['MyModuleStatusConsequences::Completion'] }
  ]

  REPORT_TEMPLATES = {}

  NOTIFIABLE_ACTIVITIES = %w(
    assign_user_to_project
    unassign_user_from_project
    change_user_role_on_project
    edit_module_comment
    delete_module_comment
    add_comment_to_module
    designate_user_to_my_module
    undesignate_user_from_my_module
    set_task_due_date
    change_task_due_date
    remove_task_due_date
    invite_user_to_team
    remove_user_from_team
    change_users_role_on_team
    set_task_start_date
    change_task_start_date
    remove_task_start_date
    change_status_on_task_flow
    sign_task
    revoke_one_signature
    reject_signature
    create_group_signature_request
    create_individual_signature_request
    delete_individual_signature_request
    delete_group_signature_request
    change_user_role_on_experiment
    change_user_role_on_my_module
  )

  DEFAULT_LABEL_TEMPLATE = {
    zpl:
      <<~HEREDOC
        ^XA
        ^MTT
        ^MUD,300,300
        ^PR2
        ^MD30
        ^LH20,20
        ^PW310
        ^CF0,23
        ^FO0,0^FD{{ITEM_ID}}^FS
        ^FO0,20^BQN,2,4^FDMA,{{ITEM_ID}}^FS
        ^FO95,30^FB180,4,0,L^FD{{NAME}}^FS^FS
        ^XZ
      HEREDOC
  }

  LABEL_TEMPLATE_FORMAT_MAP = {
    'ZebraLabelTemplate' => 'ZPL',
    'FluicsLabelTemplate' => 'Fluics'
  }

  EXTERNAL_SERVICES = %w(
    https://www.protocols.io/
    http://127.0.0.1:9100/
    https://marvinjs.chemicalize.com/
    newrelic.com
    *.newrelic.com
    *.nr-data.net
    www.recaptcha.net/
    www.gstatic.com/recaptcha/
  )

  COLORED_BACKGROUND_ACTIONS = %w(
    my_modules/protocols
    my_modules/signatures
    my_modules/activities
    results/index
    protocols/show
    preferences/index
  )

  DEFAULT_USER_NOTIFICATION_SETTINGS = {
    my_module_designation: {
      email: false,
      in_app: true
    },
    other_smart_annotation: {
      email: false,
      in_app: true
    },
    always_on: {
      email: true,
      in_app: true
    }
  }
end

# rubocop:enable Style/MutableConstant
