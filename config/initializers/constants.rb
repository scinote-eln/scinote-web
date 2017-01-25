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
  # Max characters for short text fields, in dropdownList
  NAME_TRUNCATION_LENGTH_DROPDOWN = 20
  # Max characters for long text fields
  TEXT_MAX_LENGTH = 10000
  # Max characters for rich text fields (in html format)
  RICH_TEXT_MAX_LENGTH = 50000
  # Max characters for color field (given in HEX format)
  COLOR_MAX_LENGTH = 7
  # Max characters for text in dropdown list element
  DROPDOWN_TEXT_MAX_LENGTH = 15
  # Max characters for filenames, after which they get truncated
  FILENAME_TRUNCATION_LENGTH = 50

  USER_INITIALS_MAX_LENGTH = 4
  # Password 'key stretching' factor
  PASSWORD_STRETCH_FACTOR = 10
  # Standard max length for email
  EMAIL_MAX_LENGTH = 254
  # Some big value which is still supported by all databases, no matter what
  # data type is used
  INFINITY = 2**32 / 2 - 1

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
  ACTIVITY_AND_NOTIF_SEARCH_LIMIT = 10

  # Maximum number of users that can be invited in a single action
  INVITE_USERS_LIMIT = 20

  # Maximum nr. of search results for atwho (smart annotations)
  ATWHO_SEARCH_LIMIT = 5

  #=============================================================================
  # File and data memory size
  #=============================================================================

  # Max table JSON size in MB
  TABLE_JSON_MAX_SIZE_MB = 20
  # Max uploaded file size in MB
  FILE_MAX_SIZE_MB = 50
  # Max uploaded user picture avatar size in MB
  AVATAR_MAX_SIZE_MB = 0.2

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
  LARGE_PIC_FORMAT = '800x600>'.freeze
  MEDIUM_PIC_FORMAT = '300x300>'.freeze
  THUMB_PIC_FORMAT = '100x100>'.freeze
  ICON_PIC_FORMAT = '40x40>'.freeze
  ICON_SMALL_PIC_FORMAT = '30x30>'.freeze

  # Hands-on-table number of starting columns and rows
  HANDSONTABLE_INIT_COLS_CNT = 5
  HANDSONTABLE_INIT_ROWS_CNT = 5

  # Screen width which is still suitable for sidebar to be shown, otherwise
  # hidden
  SCREEN_WIDTH_LARGE = 928

  #=============================================================================
  # Styling
  #=============================================================================

  # Dropdown top offset from the parent
  DROPDOWN_TOP_OFFSET_PX = 20

  #=============================================================================
  # Time
  #=============================================================================

  # URL expire time, used for presigned file URLs, because outsiders shouldn't
  # have access to them, but some buffer time is needed for file to be loaded
  URL_SHORT_EXPIRE_TIME = 30
  # Same as URL_EXPIRE_TIME, except for cases where the URL migth be used in
  # another page, and hence the URL mustn't expire by then (e.g. when generating
  # report and than using same HTML code in PDF, and consequently same file
  # URL); it expires in exactly one day
  URL_LONG_EXPIRE_TIME = 86_400

  #=============================================================================
  # Application colors
  #
  # NOTE: Don't use shortened syntax, e.g. #000 for #000000, as some Gems need
  # full syntax!
  #=============================================================================

  TAG_COLORS = [
    '#6C159E',
    '#159B5E',
    '#FF4500',
    '#008B8B',
    '#757575',
    '#32CD32',
    '#FFD700',
    '#48D1CC',
    '#15369E',
    '#FF69B4',
    '#CD5C5C',
    '#C9C9C9',
    '#6495ED',
    '#DC143C',
    '#FF8C00',
    '#C71585',
    '#000000'
  ].freeze

  # Theme colors
  COLOR_THEME_PRIMARY = '#37a0d9'.freeze # $color-theme-primary
  COLOR_THEME_SECONDARY = '#8fd13f'.freeze # $color-theme-secondary
  COLOR_THEME_DARK = '#6d6e71'.freeze # $color-theme-dark

  # Grayscale colors
  COLOR_WHITE = '#ffffff'.freeze # $color-white
  COLOR_ALABASTER = '#fcfcfc'.freeze # $color-alabaster
  COLOR_SNOW = '#f9f9f9'.freeze # $color-snow
  COLOR_WILD_SAND = '#f5f5f5'.freeze # $color-wild-sand
  COLOR_CONCRETE = '#f2f2f2'.freeze # $color-concrete
  COLOR_GALLERY = '#eeeeee'.freeze # $color-gallery
  COLOR_GAINSBORO = '#e3e3e3'.freeze # $color-gainsboro
  COLOR_ALTO = '#d2d2d2'.freeze # $color-alto
  COLOR_SILVER = '#c5c5c5'.freeze # $color-silver
  COLOR_DARK_GRAY = '#adadad'.freeze # $color-dark-gray
  COLOR_SILVER_CHALICE = '#a0a0a0'.freeze # $color-silver-chalice
  COLOR_GRAY = '#909088'.freeze # $color-gray
  COLOR_DOVE_GRAY = '#666666'.freeze # $color-dove-gray
  COLOR_EMPEROR = '#555555'.freeze # $color-emperor
  COLOR_MINE_SHAFT = '#333333'.freeze # $color-mine-shaft
  COLOR_NERO = '#262626'.freeze # $color-nero
  COLOR_BLACK = '#000000'.freeze # $color-black

  # Miscelaneous colors
  COLOR_MYSTIC = '#eaeff2'.freeze # $color-mystic
  COLOR_CANDLELIGHT = '#ffda23'.freeze # $color-candlelight

  # Red colors
  COLOR_MOJO = '#cf4b48'.freeze # $color-mojo
  COLOR_APPLE_BLOSSOM = '#a94442'.freeze # $color-apple-blossom
  COLOR_MILANO_RED = '#a70b05'.freeze # $color-milano-red

  #=============================================================================
  # External URLs
  #=============================================================================

  HTTP = 'http://'.freeze
  TUTORIALS_URL = (HTTP + 'scinote.net/product/tutorials/').freeze
  FAQ_URL = (HTTP + 'scinote.net/product/faq/').freeze
  SUPPORT_URL = (HTTP + 'scinote.net/plans/#prof-support').freeze
  PLANS_URL = (HTTP + 'scinote.net/plans/').freeze
  CONTACT_URL = (HTTP + 'scinote.net/about-us/').freeze
  RELEASE_NOTES_URL = (HTTP + 'scinote.net/docs/release-notes/').freeze
  # Default user picture avatar
  DEFAULT_AVATAR_URL = '/images/:style/missing.png'.freeze

  #=============================================================================
  # Other
  #=============================================================================

  # Application version
  APP_VERSION = '1.6.1'.freeze

  TEXT_EXTRACT_FILE_TYPES = [
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

  WHITELISTED_IMAGE_TYPES = [
    'gif', 'jpeg', 'pjpeg', 'png', 'x-png', 'svg+xml', 'bmp', 'tiff'
  ].freeze

  WHITELISTED_TAGS = %w(
    a b strong i em li ul ol h1 del ins h2 h3 h4 h5 h6 br sub sup p code hr div
    span u s blockquote pre
  ).freeze

  WHITELISTED_ATTRIBUTES = %w(
    href src width height alt cite datetime title class name xml:lang abbr style
  ).freeze

  # Very basic regex to check for validity of emails
  BASIC_EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  # Team name for default admin user
  DEFAULT_PRIVATE_TEAM_NAME = 'My projects'.freeze

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
  #   |   Special Thank You for supporting sciNote on Kicstarter goes       |
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
