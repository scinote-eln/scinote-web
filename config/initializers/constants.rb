#===============================================================================
# Defaults
#===============================================================================

# Application version
APP_VERSION = '1.3.1'.freeze

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

DEFAULT_PRIVATE_ORG_NAME = 'My projects'.freeze

#===============================================================================
# String length
#===============================================================================

# Min characters for short text fields
NAME_MIN_LENGTH = 2
# Max characters for short text fields
NAME_MAX_LENGTH = 255
# Max characters for short text fields, after which they get truncated
NAME_TRUNCATION_LENGTH = 25
# Max characters for long text fields
TEXT_MAX_LENGTH = 10000
# Max characters for color field (given in HEX format)
COLOR_MAX_LENGTH = 7
# Max characters for text in dropdown list element
DROPDOWN_TEXT_MAX_LENGTH = 15
# Max characters for filenames, after which they get truncated
FILENAME_TRUNCATION_LENGTH = 50

USER_INITIALS_MAX_LENGTH = 4
# Standard max length for email
EMAIL_MAX_LENGTH = 254

#===============================================================================
# Query/display limits
#===============================================================================

# General limited/unlimited query/display elements for pages
SEARCH_LIMIT = 20
SEARCH_NO_LIMIT = -1
# General limited query/display elements for popup modals
MODAL_SEARCH_LIMIT = 5
# Comments limited query/display elements for pages
COMMENTS_SEARCH_LIMIT = 10
# Activity limited query/display elements for pages
ACTIVITY_SEARCH_LIMIT = 20

#===============================================================================
# File and data memory size
#===============================================================================

# Max table JSON size in MB
TABLE_JSON_MAX_SIZE = 20
# Max uploaded file size in MB
FILE_MAX_SIZE = 50
# Max uploaded user picture avatar size in MB
AVATAR_MAX_SIZE = 0.2

#===============================================================================
# Picture size format
#===============================================================================

MEDIUM_PIC_FORMAT = '300x300>'.freeze
THUMB_PIC_FORMAT = '100x100>'.freeze
ICON_PIC_FORMAT = '40x40>'.freeze
ICON_SMALL_PIC_FORMAT = '30x30>'.freeze

#===============================================================================
# Styling
#===============================================================================

# Dropdown top offset from the parent
DROPDOWN_TOP_OFFSET_PX = 20

#===============================================================================
# Time
#===============================================================================

# URL expire time, used for presigned file URLs, because outsiders shouldn't
# have access to them, but some buffer time is needed for file to be loaded
URL_SHORT_EXPIRE_TIME = 30
# Same as URL_EXPIRE_TIME, except for cases where the URL migth be used in
# another page, and hence the URL mustn't expire by then (e.g. when generating
# report and than using same HTML code in PDF, and consequently same file URL);
# it expires in exactly one day
URL_LONG_EXPIRE_TIME = 86_400

#===============================================================================
# Space
#===============================================================================

# 1 MB of space is minimal for organizations (in B)
MINIMAL_ORGANIZATION_SPACE_TAKEN = 1.megabyte
# additional space of each file is added to its estimated
# size to account for DB indexes size etc.
ASSET_ESTIMATED_SIZE_FACTOR = 1.1

#===============================================================================
# External URL
#===============================================================================

HTTP = 'http://'.freeze
TUTORIALS_URL = (HTTP + 'scinote.net/product/tutorials/').freeze
FAQ_URL = (HTTP + 'scinote.net/product/faq/').freeze
SUPPORT_URL = (HTTP + 'scinote.net/plans/#prof-support').freeze
PLANS_URL = (HTTP + 'scinote.net/plans/').freeze
CONTACT_URL = (HTTP + 'scinote.net/about-us/').freeze
RELEASE_NOTES_URL = (HTTP + 'scinote.net/docs/release-notes/').freeze
# Default user picture avatar
DEFAULT_AVATAR_URL = '/images/:style/missing.png'.freeze

#===============================================================================
# Other
#===============================================================================

#                           )       \   /      (
#                          /|\      )\_/(     /|\
# *                       / | \    (/\|/\)   / | \                      *
# |`.____________________/__|__o____\`|'/___o__|__\___________________.'|
# |                           '^`    \|/   '^`                          |
# |                                   V                                 |
# |       _____ _                 _                            __       |
# |      |_   _| |__   __ _ _ __ | | __   _   _  ___  _   _   (  |      |
# |        | | | '_ \ / _` | '_ \| |/ /  | | | |/ _ \| | | |  |  )      |
# |        | | | | | | (_| | | | |   <   | |_| | ( | | |_| |  \_/       |
# |        |_| |_| |_|\__,_|_| |_|_|\_\   \__, |\___/ \_,|_|   _        |
# |                                       |___/               (_)       |
# |                                                                     |
# |   Special Thank You for supporting sciNote on Kicstarter goes       |
# |   to the following supporters                                       |
# | ._________________________________________________________________. |
# |'               l    /\ /     \\            \ /\   l                `|
# *                l  /   V       ))            V   \ l                 *
#                  l/            //                  \I
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
