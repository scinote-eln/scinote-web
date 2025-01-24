# frozen_string_literal: true

class GlobalConstantsController < ApplicationController
  before_action :load_global_constants
  skip_before_action :authenticate_user!, only: :index
  skip_before_action :verify_authenticity_token, only: :index

  def index; end

  private

  def load_global_constants
    @global_constants = {
      NAME_TRUNCATION_LENGTH: Constants::NAME_TRUNCATION_LENGTH,
      NAME_MAX_LENGTH: Constants::NAME_MAX_LENGTH,
      NAME_MIN_LENGTH: Constants::NAME_MIN_LENGTH,
      TEXT_MAX_LENGTH: Constants::TEXT_MAX_LENGTH,
      TABLE_CARD_MIN_WIDTH: 340,
      TABLE_CARD_GAP: 16,
      FILENAME_TRUNCATION_LENGTH: Constants::FILENAME_TRUNCATION_LENGTH,
      FILE_MAX_SIZE_MB: Rails.configuration.x.file_max_size_mb,
      REPOSITORY_LIST_ITEMS_PER_COLUMN: Constants::REPOSITORY_LIST_ITEMS_PER_COLUMN,
      REPOSITORY_CHECKLIST_ITEMS_PER_COLUMN: Constants::REPOSITORY_CHECKLIST_ITEMS_PER_COLUMN,
      REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN: Constants::REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN,
      HAS_UNSAVED_DATA_CLASS_NAME: 'has-unsaved-data',
      DEFAULT_ELEMENTS_PER_PAGE: Constants::DEFAULT_ELEMENTS_PER_PAGE,
      FILENAME_MAX_LENGTH: Constants::FILENAME_MAX_LENGTH,
      FAST_STATUS_POLLING_INTERVAL: Constants::FAST_STATUS_POLLING_INTERVAL,
      SLOW_STATUS_POLLING_INTERVAL: Constants::SLOW_STATUS_POLLING_INTERVAL,
      ASSET_POLLING_INTERVAL: Constants::ASSET_POLLING_INTERVAL,
      ASSET_SYNC_URL: Constants::ASSET_SYNC_URL,
      GLOBAL_SEARCH_PREVIEW_LIMIT: Constants::GLOBAL_SEARCH_PREVIEW_LIMIT,
      SEARCH_LIMIT: Constants::SEARCH_LIMIT,
      SCINOTE_EDIT_RESTRICTED_EXTENSIONS: Constants::SCINOTE_EDIT_RESTRICTED_EXTENSIONS,
      SCINOTE_EDIT_LATEST_JSON_URL: Constants::SCINOTE_EDIT_LATEST_JSON_URL
    }
  end
end
