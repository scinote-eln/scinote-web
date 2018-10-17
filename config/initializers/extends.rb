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
  NOTIFICATIONS_TYPES = { assignment: 0,
                          recent_changes: 1,
                          system_message: 2,
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
end
