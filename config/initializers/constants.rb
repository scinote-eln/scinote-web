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
  RICH_TEXT_MAX_LENGTH = 50000
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
  ACTIVITY_AND_NOTIF_SEARCH_LIMIT = 20

  # Maximum number of users that can be invited in a single action
  INVITE_USERS_LIMIT = 20

  # Maximum nr. of search results for atwho (smart annotations)
  ATWHO_SEARCH_LIMIT = 5

  # Max characters for repository name in Atwho modal
  ATWHO_REP_NAME_LIMIT = 16

  # Number of protocols in recent protocol dropdown
  RECENT_PROTOCOL_LIMIT = 14

  #=============================================================================
  # File and data memory size
  #=============================================================================

  # Max table JSON size in MB
  TABLE_JSON_MAX_SIZE_MB = 20
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
  REPORT_DOCX_EXPERIMENT_TITLE_SIZE = 28
  REPORT_DOCX_MY_MODULE_TITLE_SIZE = 24
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

  TAG_COLORS = [
    '#6C159E',
    '#159B5E',
    '#FF4500',
    '#008B8B',
    '#757575',
    '#2CB72C',
    '#F5AD00',
    '#0ECDC0',
    '#15369E',
    '#FF69B4',
    '#CD5C5C',
    '#ADADAD',
    '#6495ED',
    '#DC143C',
    '#FF8C00',
    '#C71585',
    '#000000'
  ].freeze

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
  FONT_FAMILY_BASE = 'Lato,"Open Sans",Arial,Helvetica,sans-serif;'.freeze # $font-family-base

  #=============================================================================
  # External URLs
  #=============================================================================

  HTTP = 'http://'.freeze
  TUTORIALS_URL = (HTTP + 'goo.gl/YH3fXA').freeze
  SUPPORT_URL = (HTTP + 'goo.gl/Jb9WXx').freeze
  # Default user picture avatar
  DEFAULT_AVATAR_URL = '/images/:style/missing.png'.freeze

  ACADEMY_BL_LINK = 'https://scinote.net/academy/?utm_source=SciNote%20software%20BL&utm_medium=SciNote%20software%20BL'.freeze
  ACADEMY_TR_LINK = 'https://scinote.net/academy/?utm_source=SciNote%20software%20TR&utm_medium=SciNote%20software%20TR'.freeze

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
          page_id: 1,
          fields: 'id,title,authors,created_on,uri,stats,published_on'
        }
      },
      publications: {
        default_query_params: {
          latest: 50
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
    'gif', 'jpeg', 'pjpeg', 'png', 'x-png', 'svg+xml', 'bmp', 'tiff'
  ].freeze

  WHITELISTED_IMAGE_TYPES_EDITABLE = %w(
    jpeg pjpeg png
  ).freeze

  WHITELISTED_TAGS = %w(
    a b strong i em li ul ol h1 del ins h2 h3 h4 h5 h6 br sub sup p code hr div
    span u s blockquote pre col colgroup table thead tbody th tr td img
  ).freeze

  WHITELISTED_ATTRIBUTES = [
    'href', 'src', 'width', 'height', 'alt', 'cite', 'datetime', 'title',
    'class', 'name', 'xml:lang', 'abbr', 'style', 'target', :data
  ].freeze

  WHITELISTED_CSS_ATTRIBUTES = {
    allow_comments: false,
    allow_hacks: false,
    at_rules_with_properties: %w[
      bottom-center bottom-left bottom-left-corner bottom-right
      bottom-right-corner font-face left-bottom left-middle left-top page
      right-bottom right-middle right-top top-center top-left
      top-left-corner top-right top-right-corner
    ],
    at_rules_with_styles: %w[
      -moz-keyframes -o-keyframes -webkit-keyframes document
      keyframes media supports
    ],
    protocols: ['http', 'https', :relative],
    properties: %w[
      -moz-appearance
      -moz-background-inline-policy
      -moz-box-sizing
      -moz-column-count
      -moz-column-fill
      -moz-column-gap
      -moz-column-rule
      -moz-column-rule-color
      -moz-column-rule-style
      -moz-column-rule-width
      -moz-column-width
      -moz-font-feature-settings
      -moz-font-language-override
      -moz-hyphens
      -moz-text-align-last
      -moz-text-decoration-color
      -moz-text-decoration-line
      -moz-text-decoration-style
      -moz-text-size-adjust
      -ms-background-position-x
      -ms-background-position-y
      -ms-block-progression
      -ms-content-zoom-chaining
      -ms-content-zoom-limit
      -ms-content-zoom-limit-max
      -ms-content-zoom-limit-min
      -ms-content-zoom-snap
      -ms-content-zoom-snap-points
      -ms-content-zoom-snap-type
      -ms-content-zooming
      -ms-filter
      -ms-flex
      -ms-flex-align
      -ms-flex-direction
      -ms-flex-order
      -ms-flex-pack
      -ms-flex-wrap
      -ms-flow-from
      -ms-flow-into
      -ms-grid-column
      -ms-grid-column-align
      -ms-grid-column-span
      -ms-grid-columns
      -ms-grid-row
      -ms-grid-row-align
      -ms-grid-row-span
      -ms-grid-rows
      -ms-high-contrast-adjust
      -ms-hyphenate-limit-chars
      -ms-hyphenate-limit-lines
      -ms-hyphenate-limit-zone
      -ms-hyphens
      -ms-ime-mode
      -ms-interpolation-mode
      -ms-layout-flow
      -ms-layout-grid
      -ms-layout-grid-char
      -ms-layout-grid-line
      -ms-layout-grid-mode
      -ms-layout-grid-type
      -ms-overflow-style
      -ms-overflow-x
      -ms-overflow-y
      -ms-progress-appearance
      -ms-scroll-chaining
      -ms-scroll-limit
      -ms-scroll-limit-x-max
      -ms-scroll-limit-x-min
      -ms-scroll-limit-y-max
      -ms-scroll-limit-y-min
      -ms-scroll-rails
      -ms-scroll-snap-points-x
      -ms-scroll-snap-points-y
      -ms-scroll-snap-type
      -ms-scroll-snap-x
      -ms-scroll-snap-y
      -ms-scroll-translation
      -ms-scrollbar-arrow-color
      -ms-scrollbar-base-color
      -ms-scrollbar-darkshadow-color
      -ms-scrollbar-face-color
      -ms-scrollbar-highlight-color
      -ms-scrollbar-shadow-color
      -ms-scrollbar-track-color
      -ms-text-align-last
      -ms-text-autospace
      -ms-text-justify
      -ms-text-kashida-space
      -ms-text-overflow
      -ms-text-size-adjust
      -ms-text-underline-position
      -ms-touch-action
      -ms-user-select
      -ms-word-break
      -ms-word-wrap
      -ms-wrap-flow
      -ms-wrap-margin
      -ms-wrap-through
      -ms-writing-mode
      -ms-zoom
      -webkit-align-content
      -webkit-align-items
      -webkit-align-self
      -webkit-animation
      -webkit-animation-delay
      -webkit-animation-direction
      -webkit-animation-duration
      -webkit-animation-fill-mode
      -webkit-animation-iteration-count
      -webkit-animation-name
      -webkit-animation-play-state
      -webkit-animation-timing-function
      -webkit-appearance
      -webkit-backface-visibility
      -webkit-background-blend-mode
      -webkit-background-clip
      -webkit-background-composite
      -webkit-background-origin
      -webkit-background-size
      -webkit-blend-mode
      -webkit-border-after
      -webkit-border-after-color
      -webkit-border-after-style
      -webkit-border-after-width
      -webkit-border-before
      -webkit-border-before-color
      -webkit-border-before-style
      -webkit-border-before-width
      -webkit-border-bottom-left-radius
      -webkit-border-bottom-right-radius
      -webkit-border-end
      -webkit-border-end-color
      -webkit-border-end-style
      -webkit-border-end-width
      -webkit-border-fit
      -webkit-border-image
      -webkit-border-radius
      -webkit-border-start
      -webkit-border-start-color
      -webkit-border-start-style
      -webkit-border-start-width
      -webkit-border-top-left-radius
      -webkit-border-top-right-radius
      -webkit-box-align
      -webkit-box-decoration-break
      -webkit-box-flex
      -webkit-box-flex-group
      -webkit-box-lines
      -webkit-box-ordinal-group
      -webkit-box-orient
      -webkit-box-pack
      -webkit-box-reflect
      -webkit-box-shadow
      -webkit-box-sizing
      -webkit-clip-path
      -webkit-column-axis
      -webkit-column-break-after
      -webkit-column-break-before
      -webkit-column-break-inside
      -webkit-column-count
      -webkit-column-gap
      -webkit-column-progression
      -webkit-column-rule
      -webkit-column-rule-color
      -webkit-column-rule-style
      -webkit-column-rule-width
      -webkit-column-span
      -webkit-column-width
      -webkit-columns
      -webkit-filter
      -webkit-flex
      -webkit-flex-basis
      -webkit-flex-direction
      -webkit-flex-flow
      -webkit-flex-grow
      -webkit-flex-shrink
      -webkit-flex-wrap
      -webkit-flow-from
      -webkit-flow-into
      -webkit-font-size-delta
      -webkit-font-smoothing
      -webkit-grid-area
      -webkit-grid-auto-columns
      -webkit-grid-auto-flow
      -webkit-grid-auto-rows
      -webkit-grid-column
      -webkit-grid-column-end
      -webkit-grid-column-start
      -webkit-grid-definition-columns
      -webkit-grid-definition-rows
      -webkit-grid-row
      -webkit-grid-row-end
      -webkit-grid-row-start
      -webkit-justify-content
      -webkit-line-clamp
      -webkit-logical-height
      -webkit-logical-width
      -webkit-margin-after
      -webkit-margin-after-collapse
      -webkit-margin-before
      -webkit-margin-before-collapse
      -webkit-margin-bottom-collapse
      -webkit-margin-collapse
      -webkit-margin-end
      -webkit-margin-start
      -webkit-margin-top-collapse
      -webkit-marquee
      -webkit-marquee-direction
      -webkit-marquee-increment
      -webkit-marquee-repetition
      -webkit-marquee-speed
      -webkit-marquee-style
      -webkit-mask
      -webkit-mask-box-image
      -webkit-mask-box-image-outset
      -webkit-mask-box-image-repeat
      -webkit-mask-box-image-slice
      -webkit-mask-box-image-source
      -webkit-mask-box-image-width
      -webkit-mask-clip
      -webkit-mask-composite
      -webkit-mask-image
      -webkit-mask-origin
      -webkit-mask-position
      -webkit-mask-position-x
      -webkit-mask-position-y
      -webkit-mask-repeat
      -webkit-mask-repeat-x
      -webkit-mask-repeat-y
      -webkit-mask-size
      -webkit-mask-source-type
      -webkit-max-logical-height
      -webkit-max-logical-width
      -webkit-min-logical-height
      -webkit-min-logical-width
      -webkit-opacity
      -webkit-order
      -webkit-padding-after
      -webkit-padding-before
      -webkit-padding-end
      -webkit-padding-start
      -webkit-perspective
      -webkit-perspective-origin
      -webkit-perspective-origin-x
      -webkit-perspective-origin-y
      -webkit-region-break-after
      -webkit-region-break-before
      -webkit-region-break-inside
      -webkit-region-fragment
      -webkit-shape-inside
      -webkit-shape-margin
      -webkit-shape-outside
      -webkit-shape-padding
      -webkit-svg-shadow
      -webkit-tap-highlight-color
      -webkit-text-decoration
      -webkit-text-decoration-color
      -webkit-text-decoration-line
      -webkit-text-decoration-style
      -webkit-text-size-adjust
      -webkit-touch-callout
      -webkit-transform
      -webkit-transform-origin
      -webkit-transform-origin-x
      -webkit-transform-origin-y
      -webkit-transform-origin-z
      -webkit-transform-style
      -webkit-transition
      -webkit-transition-delay
      -webkit-transition-duration
      -webkit-transition-property
      -webkit-transition-timing-function
      -webkit-user-drag
      -webkit-wrap-flow
      -webkit-wrap-through
      align-content
      align-items
      align-self
      alignment-adjust
      alignment-baseline
      all
      anchor-point
      animation
      animation-delay
      animation-direction
      animation-duration
      animation-fill-mode
      animation-iteration-count
      animation-name
      animation-play-state
      animation-timing-function
      azimuth
      backface-visibility
      background
      background-attachment
      background-clip
      background-color
      background-image
      background-origin
      background-position
      background-repeat
      background-size
      baseline-shift
      binding
      bleed
      bookmark-label
      bookmark-level
      bookmark-state
      border
      border-bottom
      border-bottom-color
      border-bottom-left-radius
      border-bottom-right-radius
      border-bottom-style
      border-bottom-width
      border-collapse
      border-color
      border-image
      border-image-outset
      border-image-repeat
      border-image-slice
      border-image-source
      border-image-width
      border-left
      border-left-color
      border-left-style
      border-left-width
      border-radius
      border-right
      border-right-color
      border-right-style
      border-right-width
      border-spacing
      border-style
      border-top
      border-top-color
      border-top-left-radius
      border-top-right-radius
      border-top-style
      border-top-width
      border-width
      bottom
      box-decoration-break
      box-shadow
      box-sizing
      box-snap
      box-suppress
      break-after
      break-before
      break-inside
      caption-side
      chains
      clear
      clip
      clip-path
      clip-rule
      color
      color-interpolation-filters
      column-count
      column-fill
      column-gap
      column-rule
      column-rule-color
      column-rule-style
      column-rule-width
      column-span
      column-width
      columns
      contain
      content
      counter-increment
      counter-reset
      counter-set
      crop
      cue
      cue-after
      cue-before
      cursor
      direction
      display
      display-inside
      display-list
      display-outside
      dominant-baseline
      elevation
      empty-cells
      filter
      flex
      flex-basis
      flex-direction
      flex-flow
      flex-grow
      flex-shrink
      flex-wrap
      float
      float-offset
      flood-color
      flood-opacity
      flow-from
      flow-into
      font
      font-family
      font-feature-settings
      font-kerning
      font-language-override
      font-size
      font-size-adjust
      font-stretch
      font-style
      font-synthesis
      font-variant
      font-variant-alternates
      font-variant-caps
      font-variant-east-asian
      font-variant-ligatures
      font-variant-numeric
      font-variant-position
      font-weight
      grid
      grid-area
      grid-auto-columns
      grid-auto-flow
      grid-auto-rows
      grid-column
      grid-column-end
      grid-column-start
      grid-row
      grid-row-end
      grid-row-start
      grid-template
      grid-template-areas
      grid-template-columns
      grid-template-rows
      hanging-punctuation
      height
      hyphens
      icon
      image-orientation
      image-rendering
      image-resolution
      ime-mode
      initial-letters
      inline-box-align
      justify-content
      justify-items
      justify-self
      left
      letter-spacing
      lighting-color
      line-box-contain
      line-break
      line-grid
      line-height
      line-snap
      line-stacking
      line-stacking-ruby
      line-stacking-shift
      line-stacking-strategy
      list-style
      list-style-image
      list-style-position
      list-style-type
      margin
      margin-bottom
      margin-left
      margin-right
      margin-top
      marker-offset
      marker-side
      marks
      mask
      mask-box
      mask-box-outset
      mask-box-repeat
      mask-box-slice
      mask-box-source
      mask-box-width
      mask-clip
      mask-image
      mask-origin
      mask-position
      mask-repeat
      mask-size
      mask-source-type
      mask-type
      max-height
      max-lines
      max-width
      min-height
      min-width
      move-to
      nav-down
      nav-index
      nav-left
      nav-right
      nav-up
      object-fit
      object-position
      opacity
      order
      orphans
      outline
      outline-color
      outline-offset
      outline-style
      outline-width
      overflow
      overflow-wrap
      overflow-x
      overflow-y
      padding
      padding-bottom
      padding-left
      padding-right
      padding-top
      page
      page-break-after
      page-break-before
      page-break-inside
      page-policy
      pause
      pause-after
      pause-before
      perspective
      perspective-origin
      pitch
      pitch-range
      play-during
      position
      presentation-level
      quotes
      region-fragment
      resize
      rest
      rest-after
      rest-before
      richness
      right
      rotation
      rotation-point
      ruby-align
      ruby-merge
      ruby-position
      shape-image-threshold
      shape-margin
      shape-outside
      size
      speak
      speak-as
      speak-header
      speak-numeral
      speak-punctuation
      speech-rate
      stress
      string-set
      tab-size
      table-layout
      text-align
      text-align-last
      text-combine-horizontal
      text-combine-upright
      text-decoration
      text-decoration-color
      text-decoration-line
      text-decoration-skip
      text-decoration-style
      text-emphasis
      text-emphasis-color
      text-emphasis-position
      text-emphasis-style
      text-height
      text-indent
      text-justify
      text-orientation
      text-overflow
      text-rendering
      text-shadow
      text-size-adjust
      text-space-collapse
      text-transform
      text-underline-position
      text-wrap
      top
      touch-action
      transform
      transform-origin
      transform-style
      transition
      transition-delay
      transition-duration
      transition-property
      transition-timing-function
      unicode-bidi
      unicode-range
      vertical-align
      visibility
      voice-balance
      voice-duration
      voice-family
      voice-pitch
      voice-range
      voice-rate
      voice-stress
      voice-volume
      volume
      white-space
      widows
      width
      will-change
      word-break
      word-spacing
      word-wrap
      wrap-flow
      wrap-through
      writing-mode
      z-index
    ]
  }.freeze

  # Repository default table state
  REPOSITORY_TABLE_DEFAULT_STATE = {
    'time' => 0,
    'start' => 0,
    'length' => 6,
    'order' => [[2, 'asc']], # Default sorting by 'ID' column
    'search' => { 'search' => '',
                  'smart' => true,
                  'regex' => false,
                  'caseInsensitive' => true },
    'columns' => [],
    'assigned' => 'assigned',
    'ColReorder' => [*0..5]
  }
  6.times do |i|
    REPOSITORY_TABLE_DEFAULT_STATE['columns'] << {
      'visible' => true,
      'searchable' => (i >= 1), # Checkboxes column is not searchable
      'search' => { 'search' => '',
                    'smart' => true,
                    'regex' => false,
                    'caseInsensitive' => true }
    }
  end
  REPOSITORY_TABLE_DEFAULT_STATE.freeze
  # For default custom column template, any searchable default
  # column can be reused
  REPOSITORY_TABLE_STATE_CUSTOM_COLUMN_TEMPLATE =
    REPOSITORY_TABLE_DEFAULT_STATE['columns'][1].deep_dup
                                                .freeze

  EXPORTABLE_ZIP_EXPIRATION_DAYS = 7

  REPOSITORY_LIST_ITEMS_PER_COLUMN = 500
  REPOSITORY_CHECKLIST_ITEMS_PER_COLUMN = 50
  REPOSITORY_NUMBER_TYPE_DEFAULT_DECIMALS = 2
  REPOSITORY_NUMBER_TYPE_MAX_DECIMALS = 10

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

  # Very basic regex to check for validity of emails
  BASIC_EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  TINY_MCE_ASSET_REGEX = /data-mce-token="(\w+)"/

  # Team name for default admin user
  DEFAULT_PRIVATE_TEAM_NAME = 'My projects'.freeze

  TEMPLATES_PROJECT_NAME = 'Templates'.freeze

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
