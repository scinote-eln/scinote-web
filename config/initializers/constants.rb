# Application version
APP_VERSION = "1.0.0"

TAG_COLORS = [
  "#6C159E",
  "#159B5E",
  "#FF4500",
  "#008B8B",
  "#757575",
  "#32CD32",
  "#FFD700",
  "#48D1CC",
  "#15369E",
  "#FF69B4",
  "#CD5C5C",
  "#C9C9C9",
  "#6495ED",
  "#DC143C",
  "#FF8C00",
  "#C71585",
  "#000000"
]

SEARCH_LIMIT = 20

SHOW_ALL_RESULTS = -1

TEXT_EXTRACT_FILE_TYPES = [
  "application/pdf",
  "application/rtf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  "application/vnd.oasis.opendocument.presentation",
  "application/vnd.oasis.opendocument.spreadsheet",
  "application/vnd.oasis.opendocument.text",
  "application/vnd.ms-excel",
  "application/vnd.ms-powerpoint",
  "application/vnd.ms-word",
  "text/plain"
]

# 1 MB of space is minimal for organizations
MINIMAL_ORGANIZATION_SPACE_TAKEN = 1024*1024

# additional space of each file is added to its estimated
# size to account for DB indexes size etc.
ASSET_ESTIMATED_SIZE_FACTOR = 1.1

DEFAULT_PRIVATE_ORG_NAME = "My projects"
