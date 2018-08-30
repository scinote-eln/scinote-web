# after_initialize is used because routes need to be initialzed
Rails.application.config.after_initialize do
  #Rails.application.reload_routes!
  include RepositoryDatatableHelper
  #include Rails.application.routes.url_helpers



  Gon.global.DROPDOWN_TOP_OFFSET_PX = Constants::DROPDOWN_TOP_OFFSET_PX
  Gon.global.HANDSONTABLE_INIT_ROWS_CNT = Constants::HANDSONTABLE_INIT_ROWS_CNT
  Gon.global.HANDSONTABLE_INIT_COLS_CNT = Constants::HANDSONTABLE_INIT_COLS_CNT
  Gon.global.TEXT_MAX_LENGTH = Constants::TEXT_MAX_LENGTH
  Gon.global.COLOR_WHITE = Constants::COLOR_WHITE
  Gon.global.NAME_MIN_LENGTH = Constants::NAME_MIN_LENGTH
  Gon.global.NAME_MAX_LENGTH = Constants::NAME_MAX_LENGTH
  Gon.global.NAME_TRUNCATION_LENGTH = Constants::NAME_TRUNCATION_LENGTH
  Gon.global.NAME_TRUNCATION_LENGTH_DROPDOWN = Constants::NAME_TRUNCATION_LENGTH_DROPDOWN

  Gon.global.ATWHO_SEARCH_LIMIT = Constants::ATWHO_SEARCH_LIMIT
  Gon.global.FILENAME_TRUNCATION_LENGTH = Constants::FILENAME_TRUNCATION_LENGTH
  Gon.global.AVATAR_MAX_SIZE_MB =  Constants::AVATAR_MAX_SIZE_MB.megabytes
  Gon.global.INVITE_USERS_LIMIT =  Constants::INVITE_USERS_LIMIT


  Gon.global.LIB_REPCOL_NO_PERMISSIONS = I18n.t(
    'libraries.repository_columns.no_permissions'
  )
  Gon.global.LIB_REPCOL_INDEX_EDITCOL = I18n.t(
    'libraries.repository_columns.index.edit_column'
  )
  Gon.global.LIB_REPCOL_INDEX_DELCOL = I18n.t(
    'libraries.repository_columns.index.delete_column'
  )
  Gon.global.ATWHO_USERS_NAV1 =  I18n.t('atwho.users.navigate_1')
  Gon.global.ATWHO_USERS_NAV2 =  I18n.t('atwho.users.navigate_2')
  Gon.global.ATWHO_USERS_CONF1 =  I18n.t('atwho.users.confirm_1')
  Gon.global.ATWHO_USERS_CONF2 =  I18n.t('atwho.users.confirm_2')
  Gon.global.ATWHO_USERS_DSMS1 =  I18n.t('atwho.users.dismiss_1')
  Gon.global.ATWHO_USERS_DSMS2 =  I18n.t('atwho.users.dismiss_2')
  Gon.global.ATWHO_USERS_TITLE =  I18n.t('atwho.users.title')
  Gon.global.ATWHO_NORES =  I18n.t('atwho.no_results')
  Gon.global.ATWHO_RES_ARCH = I18n.t('atwho.res.archived')
  Gon.global.ASSETS_CLIPBOARD_MODAL_TITLE = I18n.t(
    'assets.from_clipboard.modal_title'
  )
  Gon.global.ASSETS_CLIPBOARD_IMG_PREVIEW = I18n.t(
    'assets.from_clipboard.image_preview'
  )
  Gon.global.ASSETS_CLIPBOARD_FILE_NAME = I18n.t('assets.from_clipboard.file_name')
  Gon.global.ASSETS_CLIPBOARD_FILE_NAME_PLACEHOLDER = I18n.t(
    'assets.from_clipboard.file_name_placeholder'
  )
  Gon.global.GENERAL_CANCEL = I18n.t('general.cancel')
  Gon.global.GENERAL_FILE_PROCESSING = I18n.t('general.file.processing')
  Gon.global.GENERAL_SAVE =  I18n.t('general.save')
  Gon.global.GENERAL_EDIT =  I18n.t('general.edit')
  Gon.global.SAMPLES_COLUMNS_VISIBILITY = I18n.t('samples.columns_visibility')
  Gon.global.SAMPLES_COLUMNS_DELETE = I18n.t('samples.columns_delete')


  Gon.global.ASSETS_CLIPBOARD_ADD_IMAGE = I18n.t('assets.from_clipboard.add_image')
  Gon.global.ASSETS_DRAGNDROP_FILE_LABEL = I18n.t('assets.drag_n_drop.file_label')
  Gon.global.GENERAL_TEXT_LENGTH_TOO_LONG = I18n.t(
    'general.text.length_too_long', max_length: Constants::NAME_MAX_LENGTH
  )
  Gon.global.GENERAL_FILE_SIZE_EXCEEDED_AVATAR = I18n.t ('general.file.size_exceeded'), file_size: Constants::AVATAR_MAX_SIZE_MB
  Gon.global.USERS_REGISTRATIONS_EDIT_AVATAR_TOTAL_SIZE = I18n.t 'users.registrations.edit.avatar_total_size', size: Constants::AVATAR_MAX_SIZE_MB
  Gon.global.PROJECTS_REPORTS_SAVE_PDF_ASSET_PRESENT_WARNING_HTML = I18n.t(
    'projects.reports.new.save_PDF_to_inventory_modal.asset_present_warning_html'
  )
  Gon.global.PROJECTS_REPORTS_SAVE_PDF_NOTHING_SELECTED = I18n.t(
    'projects.reports.new.save_PDF_to_inventory_modal.nothing_selected'
  )

  Gon.global.TINYMCE_UPLOAD_WINDOW_TITLE =  I18n.t 'tiny_mce.upload_window_title'
  Gon.global.TINYMCE_UPLOAD_WINDOW_LABEL =  I18n.t 'tiny_mce.upload_window_label'
  Gon.global.TINYMCE_INSERT_BTN =  I18n.t 'tiny_mce.insert_btn'
  Gon.global.TINYMCE_ERROR_MESSAGE = I18n.t 'tiny_mce.error_message'
  Gon.global.TINYMCE_SERVER_NOT_RESPONDED = I18n.t 'tiny_mce.server_not_respond'

  Gon.global.HIGHLIGHTJS_GITHUB_THEME = ActionController::Base.helpers.asset_path('highlightjs-github-theme')

  Gon.global.DEFAULT_TABLE_COLUMNS = default_table_columns
  Gon.global.DEFAULT_TABLE_ORDER_AS_JS_ARRAY = default_table_order_as_js_array

  # The below constants cant be used because this loads before routes
  #Gon.global.RAILS_URL_HELPER_REPORTS_VISISBLE_PROJECTS_PATH = reports_visible_projects_path
  #Gon.global.RAILS_URL_HELPER_AVAILABLE_ROWS_PATH = available_rows_path
  #Gon.global.RAILS_URL_HELPER_AVAILABLE_ASSET_TYPE_COLUMNS_PATH = available_asset_type_columns_path
  #Gon.global.RAILS_URL_HELPER_REPORTS_AVAILABLE_REPOSITORIES_PATH =  reports_available_repositories_path
  #Gon.global.RAIL_URL_HELPER_REPORTS_SAVE_PDF_TO_INVENTORY_ITEM_PATH = reports_save_pdf_to_inventory_item_path
  #Gon.global.RAILS_URL_HELPER_REPOSITORY_LIST_ITEMS_PATH = repository_list_items_path
  #Gon.global.RAILS_URL_HELPER_TINY_MCE_ASSETS_PATH = tiny_mce_assets_path
  # The above constants cant be initialized yet because the routes arent initialized.
  # So they are implemented in the controllers for their functions.

end
