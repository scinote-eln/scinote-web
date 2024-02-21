class Constants
  #=============================================================================
  # String lengths
  #=============================================================================

  # Min characters for short text fields
  NAME_MIN_LENGTH = 2
  # Max characters for short text fields
  NAME_MAX_LENGTH = 255
  # Max characters for short text fields, after which they get truncated
  NAME_TRUNCATION_LENGTH = 25
  # Max edge length
  MAX_EDGE_LENGTH = 75
  # Max character for listing projects in dropdown
  MAX_NAME_TRUNCATION = 150
  # Max characters for short text fields, in dropdownList
  NAME_TRUNCATION_LENGTH_DROPDOWN = 20
  # Max characters for long text fields
  TEXT_MAX_LENGTH = 10000
  # Max characters for rich text fields (in html format)
  RICH_TEXT_MAX_LENGTH = 1000000
  # Max characters for color field (given in HEX format)
  COLOR_MAX_LENGTH = 7
  # Max characters for text in dropdown list element
  DROPDOWN_TEXT_MAX_LENGTH = 15
  # Max characters for text in modal list element
  MODAL_TEXT_MAX_LENGTH = 55
  # Max characters limit for (on most operating systems, it's ~255 characters,
  # but this is with a bit more safety margin)
  FILENAME_MAX_LENGTH = 100
  # Max characters for filenames, after which they get truncated
  FILENAME_TRUNCATION_LENGTH = 50
  # Max characters for names of exported files and folders, after which they get
  # truncated
  EXPORTED_FILENAME_TRUNCATION_LENGTH = 20

  USER_INITIALS_MAX_LENGTH = 4
  # Password 'key stretching' factor
  PASSWORD_STRETCH_FACTOR = 10
  # Standard max length for email
  EMAIL_MAX_LENGTH = 254
  # Some big value which is still supported by all databases, no matter what
  # data type is used
  INFINITY = ((2**32) / 2) - 1

  # Prevents integer overflow for reminder delta seconds
  MAX_NUMBER_OF_REMINDER_WEEKS = 816

  #=============================================================================
  # Query/display limits
  #=============================================================================

  # General limited/unlimited query/display elements for pages
  SEARCH_LIMIT = 20
  SEARCH_NO_LIMIT = -1
  # General limited query/display elements for popup modals
  MODAL_SEARCH_LIMIT = 5
  # Comments limited query/display elements for pages
  COMMENTS_SEARCH_LIMIT = 10
  # Activity limited query/display elements for pages
  ACTIVITY_AND_NOTIF_SEARCH_LIMIT = 20
  # Infinite Scroll load limit (elements per page)
  INFINITE_SCROLL_LIMIT = 20
  # Maximum number of users that can be invited in a single action
  INVITE_USERS_LIMIT = 20
  # Maximum nr. of search results for atwho (smart annotations)
  ATWHO_SEARCH_LIMIT = 10
  # Max characters for repository name in Atwho modal
  ATWHO_REP_NAME_LIMIT = 16
  # Results limited query/display elements for pages
  RESULTS_PER_PAGE_LIMIT = 10
  #Experiments more button appears
  EXPERIMENT_LONG_DESCRIPTION = 80
  # Infinite scroll default elements per page
  DEFAULT_ELEMENTS_PER_PAGE = 20
  # Default navigator width
  DEFAULT_NAV_WIDTH = 208

  #=============================================================================
  # File and data memory size
  #=============================================================================

  # Max table JSON size in MB
  TABLE_JSON_MAX_SIZE_MB = 20
  # Max uploaded user picture avatar size in MB
  AVATAR_MAX_SIZE_MB = 0.2
  # PDF preview file limit in MB
  PDF_PREVIEW_MAX_SIZE_MB = 10


  #=============================================================================
  # Application space
  #=============================================================================

  # Minimal space needed for team (in B)
  MINIMAL_TEAM_SPACE_TAKEN = 1.megabyte
  # Additional space of each file is added to its estimated size to account for
  # DB indexes size etc.
  ASSET_ESTIMATED_SIZE_FACTOR = 1.1

  #=============================================================================
  # Format sizes
  #=============================================================================

  # Picture size formats
  LARGE_PIC_FORMAT = [800, 600].freeze
  MEDIUM_PIC_FORMAT = [300, 300].freeze
  THUMB_PIC_FORMAT = [100, 100].freeze
  ICON_PIC_FORMAT = [40, 40].freeze
  ICON_SMALL_PIC_FORMAT = [30, 30].freeze

  # Hands-on-table number of starting columns and rows
  HANDSONTABLE_INIT_COLS_CNT = 5
  HANDSONTABLE_INIT_ROWS_CNT = 5

  # Word reports format. All units in Twips.
  # A twip is 1/20 of a point. Word documents are printed at 72dpi. 1in == 72pt == 1440 twips.
  # Here is default A4
  REPORT_DOCX_WIDTH = 12240
  REPORT_DOCX_HEIGHT = 15840
  REPORT_DOCX_MARGIN_TOP = 720
  REPORT_DOCX_MARGIN_RIGHT = 720
  REPORT_DOCX_MARGIN_BOTTOM = 720
  REPORT_DOCX_MARGIN_LEFT = 720

  # Word borders in eighth point units.
  # A eighth point is 1/8 of a point. A border size of 4 is equivalent to 0.5pt.
  REPORT_DOCX_TABLE_BORDER_SIZE = 4

  # All font size in half points
  REPORT_DOCX_REPORT_TITLE_SIZE = 36
  REPORT_DOCX_EXPERIMENT_TITLE_SIZE = 32
  REPORT_DOCX_MY_MODULE_TITLE_SIZE = 28
  REPORT_DOCX_STEP_TITLE_SIZE = 22
  REPORT_DOCX_STEP_ELEMENTS_TITLE_SIZE = 20

  #=============================================================================
  # Styling
  #=============================================================================

  # Dropdown top offset from the parent
  DROPDOWN_TOP_OFFSET_PX = 20

  #=============================================================================
  # Date and time
  #=============================================================================

  # URL expire time, used for presigned file URLs, because outsiders shouldn't
  # have access to them, but some buffer time is needed for file to be loaded
  URL_SHORT_EXPIRE_TIME = 30
  # Same as URL_EXPIRE_TIME, except for cases where the URL migth be used in
  # another page, and hence the URL mustn't expire by then (e.g. when generating
  # report and than using same HTML code in PDF, and consequently same file
  # URL); it expires in exactly one day
  URL_LONG_EXPIRE_TIME = 86_400

  DEFAULT_DATE_FORMAT = '%m/%d/%Y'.freeze

  SUPPORTED_DATE_FORMATS = [
    # US formats
    '%m/%d/%Y', '%m.%d.%Y', '%m. %d. %Y', '%m-%d-%Y', '%-m/%-d/%Y',
    '%-m.%-d.%Y', '%-m. %-d. %Y', '%-m-%-d-%Y',
    # European formats
    '%d/%m/%Y', '%d.%m.%Y', '%d. %m. %Y', '%d-%b-%Y', '%Y-%m-%d',
    '%d.%b.%Y', '%Y/%b/%d', '%d, %B, %Y', '%B, %d, %Y', '%-d/%-m/%Y',
    '%-d.%-m.%Y', '%-d. %-m. %Y', '%d-%m-%Y', '%Y-%-m-%-d', '%-d-%b-%Y',
    '%Y-%b-%-d', '%-d, %B, %Y', '%B, %-d, %Y'
  ].freeze

  #=============================================================================
  # Application colors
  #
  # NOTE: Don't use shortened syntax, e.g. #000 for #000000, as some Gems need
  # full syntax!
  #=============================================================================

  TAG_COLORS = %i(
    #C4D3A0
    #5EC66F
    #46C3C8
    #A3CCE4
    #3B99FD
    #104DA9
    #6F2DC1
    #FF69B4
    #DF3562
    #AD0015
    #FF5C00
    #E9A845
    #B06500
    #663300
    #1D2939
    #98A2B3
    #DCE0E7
  ).freeze

  # Theme colors
  BRAND_PRIMARY = '#104da9'.freeze # $brand-primary

  # Grayscale colors
  COLOR_WHITE = '#ffffff'.freeze # $color-white
  COLOR_CONCRETE = '#f0f0f6'.freeze # $color-concrete
  COLOR_ALTO = '#d0d0d8'.freeze # $color-alto
  COLOR_SILVER_CHALICE = '#a0a0a8'.freeze # $color-silver-chalice
  COLOR_VOLCANO = '#404048'.freeze # $color-volcano
  COLOR_BLACK = '#231f20'.freeze # $color-black

  # Fonts
  FONT_FAMILY_BASE = 'Inter,"Open Sans",Arial,Helvetica,sans-serif;'.freeze # $font-family-base

  #=============================================================================
  # External URLs
  #=============================================================================

  HTTP = 'http://'.freeze
  TUTORIALS_URL = ENV.fetch('VIDEO_TUTORIALS_URL', "#{HTTP}goo.gl/YH3fXA").freeze
  SUPPORT_URL = ENV.fetch('KNOWLEDGE_CENTER_URL', 'https://scinote-3850750.hs-sites.com/en/knowledge').freeze
  FREE_TRIAL_URL = 'https://www.scinote.net/free-trial/?utm_source=SciNoteShare&utm_medium=FreeTrialButton&utm_campaign=Q3_2023'.freeze
  # Default user picture avatar
  DEFAULT_AVATAR_URL = '/images/:style/missing.svg'.freeze

  ACADEMY_BL_LINK = 'https://scinote.net/academy/?utm_source=SciNote%20software%20BL&utm_medium=SciNote%20software%20BL'.freeze

  PWA_URL = 'https://:pwa_domain/teams/:team_id/projects/:project_id/experiments/:experiment_id/tasks/:task_id/protocol/:protocol_id/:step_id?domain=:domain'.freeze

  TWO_FACTOR_URL = {
    google: {
      android: 'https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2',
      ios: 'https://apps.apple.com/us/app/google-authenticator/id388497605'
    },
    microsoft: {
      android: 'https://play.google.com/store/apps/details?id=com.azure.authenticator',
      ios: 'https://apps.apple.com/us/app/microsoft-authenticator/id983156458'
    },
    two_fa: {
      android: 'https://play.google.com/store/apps/details?id=com.twofasapp',
      ios: 'https://apps.apple.com/us/app/2fa-authenticator-2fas/id1217793794'
    },
  }

  SCINOTE_FLUICS_URL = 'https://www.scinote.net/fluics/'.freeze
  SCINOTE_ZEBRA_DOWNLOAD_URL = 'https://www.zebra.com/us/en/products/software/barcode-printers/link-os/browser-print.html'.freeze
  SCINOTE_ZEBRA_BLOG_URL = 'https://www.scinote.net/blog/connect-zebra-printers/'.freeze
  SCINOTE_ZEBRA_SUPPORT_URL = 'https://www.zebra.com/us/en/about-zebra/contact-zebra/contact-tech-support.html'.freeze
  TWO_FACTOR_RECOVERY_CODE_COUNT = 6
  TWO_FACTOR_RECOVERY_CODE_LENGTH = 12

  #=============================================================================
  # Protocol importers
  #=============================================================================

  PROTOCOLS_ENDPOINTS = {
    protocolsio: {
      v3: 'ProtocolsIo::V3'
    }
  }.freeze

  PROTOCOLS_IO_URL = 'https://www.protocols.io/'.freeze

  PROTOCOLS_IO_V3_API = {
    base_uri: 'https://www.protocols.io/api/v3/',
    default_timeout: 10,
    debug_level: :debug,
    sort_mappings: {
      alpha_asc: { order_field: :name, order_dir: :asc },
      alpha_desc: { order_field: :name, order_dir: :desc },
      newest: { order_field: :date, order_dir: :desc },
      oldest: { order_field: :date, order_dir: :asc }
    },
    endpoints: {
      protocols: {
        default_query_params: {
          filter: :public,
          key: '',
          order_field: :activity,
          order_dir: :desc,
          page_size: 50,
          page_id: 0,
          fields: 'id,title,authors,created_on,uri,stats,published_on'
        }
      },
      publications: {
        default_query_params: {
          latest: 20
        }
      }
    },
    source_id: 'protocolsio/v3'
  }.freeze

  PROTOCOLS_DESC_TAGS = %w(a img i br).freeze

  #=============================================================================
  # Other
  #=============================================================================

  FILE_TEXT_FORMATS = %w(doc docm docx dot dotm dotx odt rtf).freeze

  FILE_TABLE_FORMATS = %w(csv ods xls xlsb xlsm xlsx).freeze

  FILE_PRESENTATION_FORMATS =
    %w(odp pot potm potx pps ppsm ppsx ppt pptm pptx).freeze

  WOPI_EDITABLE_FORMATS = %w(
    docx docm odt xlsx xlsm xlsb ods pptx ppsx odp
  ).freeze

  TEXT_EXTRACT_FILE_TYPES = [
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
    'application/pdf',
    'application/rtf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.oasis.opendocument.presentation',
    'application/vnd.oasis.opendocument.spreadsheet',
    'application/vnd.oasis.opendocument.text',
    'application/vnd.ms-excel',
    'application/vnd.ms-powerpoint',
    'application/vnd.ms-word',
    'text/plain'
  ].freeze

  PREVIEWABLE_FILE_TYPES = TEXT_EXTRACT_FILE_TYPES

  WHITELISTED_IMAGE_TYPES = [
    'gif', 'jpeg', 'pjpeg', 'png', 'x-png', 'svg+xml', 'bmp', 'tiff', 'jpg'
  ].freeze

  WHITELISTED_IMAGE_TYPES_EDITABLE = %w(
    jpeg pjpeg png
  ).freeze

  config = Sanitize::Config::RELAXED.deep_dup
  config[:attributes][:all] << 'id'
  config[:attributes][:all] << 'contenteditable'
  config[:attributes]['img'] << 'data-mce-token'
  config[:attributes]['img'] << 'data-source-type'
  config[:attributes]['a'] << 'data-turbolinks'
  config[:protocols]['img']['src'] << 'data'
  INPUT_SANITIZE_CONFIG = Sanitize::Config.freeze_config(config)

  REPOSITORY_DEFAULT_PAGE_SIZE = 10
  REPOSITORY_LIST_ITEMS_PER_COLUMN = 500
  REPOSITORY_CHECKLIST_ITEMS_PER_COLUMN = 50
  REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN = 50
  REPOSITORY_NUMBER_TYPE_DEFAULT_DECIMALS = 2
  REPOSITORY_NUMBER_TYPE_MAX_DECIMALS = 10

  REPOSITORY_DATETIME_REMINDER_PRESET = 10

  # Repository default table state
  REPOSITORY_TABLE_DEFAULT_STATE = {
    'time' => 0,
    'start' => 0,
    'length' => REPOSITORY_DEFAULT_PAGE_SIZE,
    'order' => [[3, 'asc']], # Default sorting by 'name' column
    'columns' => [],
    'assigned' => 'assigned',
    'ColReorder' => [*0..8]
  }
  9.times do |i|
    REPOSITORY_TABLE_DEFAULT_STATE['columns'] << {
      'visible' => (i < 7 && i != 4), # relationship column is hidden by default
      'searchable' => (i >= 1 && i != 4), # Checkboxes and relationship column is not searchable
      'search' => { 'search' => '',
                    'smart' => true,
                    'regex' => false,
                    'caseInsensitive' => true }
    }
  end
  REPOSITORY_TABLE_DEFAULT_STATE.freeze

  # Repository default table state
  REPOSITORY_SNAPSHOT_TABLE_DEFAULT_STATE = {
    'time' => 0,
    'start' => 0,
    'length' => REPOSITORY_DEFAULT_PAGE_SIZE,
    'order' => [[1, 'asc']], # Default sorting by 'ID' column
    'columns' => [],
    'assigned' => 'assigned',
    'ColReorder' => [*0..4]
  }

  REPOSITORY_SNAPSHOT_TABLE_DEFAULT_STATE['columns'] = REPOSITORY_TABLE_DEFAULT_STATE['columns'][0..4]

  REPOSITORY_SNAPSHOT_TABLE_DEFAULT_STATE.freeze

  # For default custom column template, any searchable default
  # column can be reused
  REPOSITORY_TABLE_STATE_CUSTOM_COLUMN_TEMPLATE =
    REPOSITORY_TABLE_DEFAULT_STATE['columns'][1].deep_dup
                                                .freeze

  EXPORTABLE_ZIP_EXPIRATION_DAYS = 7

  REPOSITORY_LIST_ITEMS_DELIMITERS_MAP = {
    return: "\n",
    comma: ',',
    semicolon: ';',
    space: ' '
  }.freeze

  REPOSITORY_LIST_ITEMS_DELIMITERS_ICON_MAP = {
    auto: "＊",
    return: "↵",
    comma: ',',
    semicolon: ';',
    space: '⎵'
  }.freeze

  IMPORT_REPOSITORY_ITEMS_LIMIT = 2000

  DEFAULT_TEAM_REPOSITORIES_LIMIT = 6

  # Very basic regex to check for validity of emails
  BASIC_EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  TINY_MCE_ASSET_REGEX = /data-mce-token="(\w+)"/

  # Team name for default admin user
  DEFAULT_PRIVATE_TEAM_NAME = 'My projects'.freeze

  TEMPLATES_PROJECT_NAME = 'Templates'.freeze

  # Interval time for polling status state
  FAST_STATUS_POLLING_INTERVAL = 5000
  SLOW_STATUS_POLLING_INTERVAL = 10000

  # Interval time for polling asset changes when editing with SciNote Edit
  ASSET_POLLING_INTERVAL = 5000

  ASSET_SYNC_TOKEN_EXPIRATION = 1.year
  ASSET_SYNC_URL = ENV['ASSET_SYNC_URL'].freeze

  # Grover timeout in ms
  GROVER_TIMEOUT_MS = 300000

  # SciNote Edit supported versions
  MIN_SCINOTE_EDIT_VERSION = ENV['MIN_SCINOTE_EDIT_VERSION'].freeze
  MAX_SCINOTE_EDIT_VERSION = ENV['MAX_SCINOTE_EDIT_VERSION'].freeze

  #                             )       \   /      (
  #                            /|\      )\_/(     /|\
  #   *                       / | \    (/\|/\)   / | \                      *
  #   |`.____________________/__|__o____\`|'/___o__|__\___________________.'|
  #   |                           '^`    \|/   '^`                          |
  #   |                                   V                                 |
  #   |       _____ _                 _                            __       |
  #   |      |_   _| |__   __ _ _ __ | | __   _   _  ___  _   _   (  |      |
  #   |        | | | '_ \ / _` | '_ \| |/ /  | | | |/ _ \| | | |  |  )      |
  #   |        | | | | | | (_| | | | |   <   | |_| | ( | | |_| |  \_/       |
  #   |        |_| |_| |_|\__,_|_| |_|_|\_\   \__, |\___/ \_,|_|   _        |
  #   |                                       |___/               (_)       |
  #   |                                                                     |
  #   |   Special Thank You for supporting SciNote on Kicstarter goes       |
  #   |   to the following supporters                                       |
  #   | ._________________________________________________________________. |
  #   |'               l    /\ /     \\            \ /\   l                `|
  #   *                l  /   V       ))            V   \ l                 *
  #                    l/            //                  \I
  KICKSTARTER_SUPPORTERS = [
    'Manuela Lanzafame',
    'Fluckiger Rudolf',
    'Emily Gleason',
    'Benjamin E Doremus',
    'Chord Pet Wearable',
    'Chris Taylor',
    'Abraham White',
    'Ryotaro Eguchi',
    'Simon Waldherr',
    'Isaac Sandaljian',
    'Markus Rademacher'
  ].freeze
end
