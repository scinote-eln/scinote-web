# frozen_string_literal: true

class Asset < ApplicationRecord
  include ActiveStorage::Downloading
  include SearchableModel
  include DatabaseHelper
  include Encryptor
  include WopiUtil
  include ActiveStorageFileUtil
  include ImageVariantProcessing

  require 'tempfile'
  # Lock duration set to 30 minutes
  LOCK_DURATION = 60 * 30

  # ActiveStorage configuration
  has_one_attached :file

  # Paperclip validation
  # has_attached_file :file,
  #                   styles: lambda { |a|
  #                     if a.previewable_document?
  #                       {
  #                         large: { processors: [:custom_file_preview],
  #                                  geometry: Constants::LARGE_PIC_FORMAT,
  #                                  format: :jpg },
  #                         medium: { processors: [:custom_file_preview],
  #                                   geometry: Constants::MEDIUM_PIC_FORMAT,
  #                                   format: :jpg }
  #                       }
  #                     else
  #                       {
  #                         large: [Constants::LARGE_PIC_FORMAT, :jpg],
  #                         medium: [Constants::MEDIUM_PIC_FORMAT, :jpg]
  #                       }
  #                     end
  #                   },
  #                   convert_options: {
  #                     medium: '-quality 70 -strip',
  #                     all: '-background "#d2d2d2" -flatten +matte'
  #                   }

  # before_post_process :previewable?
  # before_post_process :extract_image_quality

  # adds image processing in background job
  # process_in_background :file, processing_image_url: '/images/:style/processing.gif'

  # validates_attachment :file,
  #                      presence: true,
  #                      size: {
  #                        less_than: Rails.configuration.x.file_max_size_mb.megabytes
  #                      }
  # validates :estimated_size, presence: true
  # validates :file_present, inclusion: { in: [true, false] }

  # Should be checked for any security leaks
  # do_not_validate_attachment_file_type :file

  # Asset validation
  # This could cause some problems if you create empty asset and want to
  # assign it to result
  validate :step_or_result_or_repository_asset_value
  validate :wopi_filename_valid,
           on: :wopi_file_creation

  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  belongs_to :team, optional: true
  has_one :step_asset, inverse_of: :asset, dependent: :destroy
  has_one :step, through: :step_asset, dependent: :nullify
  has_one :result_asset, inverse_of: :asset, dependent: :destroy
  has_one :result, through: :result_asset, dependent: :nullify
  has_one :repository_asset_value, inverse_of: :asset, dependent: :destroy
  has_one :repository_cell, through: :repository_asset_value,
    dependent: :nullify
  has_many :report_elements, inverse_of: :asset, dependent: :destroy
  has_one :asset_text_datum, inverse_of: :asset, dependent: :destroy

  after_save { result&.touch; step&.touch }

  attr_accessor :file_content, :file_info, :in_template

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    _current_team = nil,
    options = {}
  )

    teams = user.teams.select(:id)

    assets_in_steps = Asset.joins(:step).where(
      'steps.id IN (?)',
      Step.search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
          .select(:id)
    ).pluck(:id)

    assets_in_results = Asset.joins(:result).where(
      'results.id IN (?)',
      Result.search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
            .select(:id)
    ).pluck(:id)

    assets_in_inventories = Asset.joins(
      repository_cell: { repository_column: :repository }
    ).where('repositories.team_id IN (?)', teams).pluck(:id)

    assets =
      Asset.distinct
           .where('assets.id IN (?) OR assets.id IN (?) OR assets.id IN (?)',
                  assets_in_steps, assets_in_results, assets_in_inventories)

    new_query = Asset.left_outer_joins(:asset_text_datum)
                     .left_outer_joins(file_attachment: :blob)
                     .from(assets, 'assets')

    a_query = s_query = ''

    if options[:whole_word].to_s == 'true' ||
       options[:whole_phrase].to_s == 'true'
      like = options[:match_case].to_s == 'true' ? '~' : '~*'
      s_query = query.gsub(/[!()&|:]/, ' ')
                     .strip
                     .split(/\s+/)
                     .map { |t| t + ':*' }
      if options[:whole_word].to_s == 'true'
        a_query = query.split
                       .map { |a| Regexp.escape(a) }
                       .join('|')
        s_query = s_query.join('|')
      else
        a_query = Regexp.escape(query)
        s_query = s_query.join('&')
      end
      a_query = '\\y(' + a_query + ')\\y'
      s_query = s_query.tr('\'', '"')

      new_query = new_query.where(
        "(active_storage_blobs.filename #{like} ? " \
        "OR asset_text_data.data_vector @@ to_tsquery(?))",
        a_query,
        s_query
      )
    else
      like = options[:match_case].to_s == 'true' ? 'LIKE' : 'ILIKE'
      a_query = query.split.map { |a| "%#{sanitize_sql_like(a)}%" }

      # Trim whitespace and replace it with OR character. Make prefixed
      # wildcard search term and escape special characters.
      # For example, search term 'demo project' is transformed to
      # 'demo:*|project:*' which makes word inclusive search with postfix
      # wildcard.
      s_query = query.gsub(/[!()&|:]/, ' ')
                     .strip
                     .split(/\s+/)
                     .map { |t| t + ':*' }
                     .join('|')
                     .tr('\'', '"')
      new_query = new_query.where(
        "(active_storage_blobs.filename #{like} ANY (array[?]) " \
        "OR asset_text_data.data_vector @@ to_tsquery(?))",
        a_query,
        s_query
      )
    end

    # Show all results if needed
    if page != Constants::SEARCH_NO_LIMIT
      new_query = new_query.select('assets.*, asset_text_data.data AS data')
                           .limit(Constants::SEARCH_LIMIT)
                           .offset((page - 1) * Constants::SEARCH_LIMIT)
      Asset.select(
        "assets_search.*, ts_headline(assets_search.data, to_tsquery('" +
        sanitize_sql_for_conditions(s_query) +
        "'), 'StartSel=<mark>, StopSel=</mark>') AS headline"
      ).from(new_query, 'assets_search')
    else
      new_query
    end
  end

  def blob
    file&.blob
  end

  def previewable?
    return false unless file.attached?

    previewable_document?(blob) || previewable_image?
  end

  def medium_preview
    return file.variant(resize: Constants::MEDIUM_PIC_FORMAT) if previewable_image?

    file.preview(resize: Constants::MEDIUM_PIC_FORMAT)
  end

  def large_preview
    return file.variant(resize: Constants::LARGE_PIC_FORMAT) if previewable_image?

    file.preview(resize: Constants::LARGE_PIC_FORMAT)
  end

  def file_name
    return '' unless file.attached?

    file.blob&.filename&.sanitized
  end

  def file_size
    return 0 unless file.attached?

    file.blob&.byte_size
  end

  def content_type
    return '' unless file.attached?

    file&.blob&.content_type
  end

  def duplicate
    new_asset = dup
    return unless new_asset.save

    return new_asset unless file.attached?

    duplicate_file(new_asset)
    new_asset
  end

  def duplicate_file(to_asset)
    download_blob_to_tempfile do |tmp_file|
      to_asset.file.attach(io: tmp_file.open, filename: file_name)
    end
    to_asset.post_process_file(to_asset.team)
  end

  def extract_image_quality
    return unless ['image/jpeg', 'image/pjpeg'].include? content_type

    tempfile = file.queued_for_write[:original]
    unless tempfile.nil?
      quality = Paperclip::Processor.new(tempfile).identify(" -format '%Q' #{tempfile.path}")
      self.file_image_quality = quality.to_i
    end
  rescue StandardError => e
    Rails.logger.info "There was an error extracting image quality - #{e}"
  end

  def image?
    content_type =~ %r{^image/#{Regexp.union(Constants::WHITELISTED_IMAGE_TYPES)}}
  end

  def text?
    Constants::TEXT_EXTRACT_FILE_TYPES.any? do |v|
      file&.blob&.content_type&.start_with? v
    end
  end

  def post_process_file(team = nil)
    # Update self.empty
    update(file_present: true)

    # Extract asset text if it's of correct type
    if text?
      Rails.logger.info "Asset #{id}: Creating extract text job"
      # The extract_asset_text also includes
      # estimated size calculation
      Asset.delay(queue: :assets, run_at: 20.minutes.from_now)
           .extract_asset_text_delayed(id, in_template)
    else
      # Update asset's estimated size immediately
      update_estimated_size(team)
    end
  end

  def self.extract_asset_text_delayed(asset_id, in_template = false)
    asset = find_by_id(asset_id)
    return unless asset.present? && asset.file.attached?

    asset.extract_asset_text(in_template)
  end

  def extract_asset_text(in_template = false)
    self.in_template = in_template

    download_blob_to_tempfile do |tmp_file|
      # Start Tika as a server
      Yomu.server(:text) if !ENV['NO_TIKA_SERVER'] && Yomu.class_variable_get(:@@server_pid).nil?

      text_data = Yomu.new(tmp_file.path).text

      if asset_text_datum.present?
        # Update existing text datum if it exists
        asset_text_datum.update(data: text_data)
      else
        # Create new text datum
        AssetTextDatum.create(data: text_data, asset: self)
      end

      Rails.logger.info "Asset #{id}: Asset file successfully extracted"

      # Finally, update asset's estimated size to include
      # the data vector
      update_estimated_size(team)
    rescue StandardError => e
      Rails.logger.fatal(
        "Asset #{id}: Error extracting contents from asset "\
        "file #{file.blob.key}: #{e.message}"
      )
    end
  end

  # If team is provided, its space_taken
  # is updated as well
  def update_estimated_size(team = nil)
    return if file_size.blank? || in_template

    es = file_size
    if asset_text_datum.present? && asset_text_datum.persisted?
      asset_text_datum.reload
      es += get_octet_length_record(asset_text_datum, :data)
      es += get_octet_length_record(asset_text_datum, :data_vector)
    end
    es *= Constants::ASSET_ESTIMATED_SIZE_FACTOR
    update(estimated_size: es)
    Rails.logger.info "Asset #{id}: Estimated size successfully calculated"

    # Finally, update team's space
    if team.present?
      team.take_space(es)
      team.save
    end
  end

  def can_perform_action(action)
    if ENV['WOPI_ENABLED'] == 'true'
      file_ext = file_name.split('.').last

      if file_ext == 'wopitest' &&
         (!ENV['WOPI_TEST_ENABLED'] || ENV['WOPI_TEST_ENABLED'] == 'false')
        return false
      end

      action = get_action(file_ext, action)
      return false if action.nil?

      true
    else
      false
    end
  end

  def get_action_url(user, action, with_tokens = true)
    file_ext = file_name.split('.').last
    action = get_action(file_ext, action)
    if !action.nil?
      action_url = action.urlsrc
      if ENV['WOPI_BUSINESS_USERS'] && ENV['WOPI_BUSINESS_USERS'] == 'true'
        action_url = action_url.gsub(/<IsLicensedUser=BUSINESS_USER&>/,
                                     'IsLicensedUser=1&')
        action_url = action_url.gsub(/<IsLicensedUser=BUSINESS_USER>/,
                                     'IsLicensedUser=1')
      else
        action_url = action_url.gsub(/<IsLicensedUser=BUSINESS_USER&>/,
                                     'IsLicensedUser=0&')
        action_url = action_url.gsub(/<IsLicensedUser=BUSINESS_USER>/,
                                     'IsLicensedUser=0')
      end
      action_url = action_url.gsub(/<.*?=.*?>/, '')

      rest_url = Rails.application.routes.url_helpers.wopi_rest_endpoint_url(
        host: ENV['WOPI_ENDPOINT_URL'],
        id: id
      )
      action_url += "WOPISrc=#{rest_url}"
      if with_tokens
        token = user.get_wopi_token
        action_url + "&access_token=#{token.token}"\
        "&access_token_ttl=#{(token.ttl * 1000)}"
      else
        action_url
      end
    else
      return nil
    end
  end

  def favicon_url(action)
    file_ext = file_name.split('.').last
    action = get_action(file_ext, action)
    action.wopi_app.icon if action.try(:wopi_app)
  end

  # locked?, lock_asset and refresh_lock rely on the asset
  # being locked in the database to prevent race conditions
  def locked?
    !lock.nil?
  end

  def lock_asset(lock_string)
    self.lock = lock_string
    self.lock_ttl = Time.now.to_i + LOCK_DURATION
    delay(queue: :assets, run_at: LOCK_DURATION.seconds.from_now).unlock_expired
    save!
  end

  def refresh_lock
    self.lock_ttl = Time.now.to_i + LOCK_DURATION
    delay(queue: :assets, run_at: LOCK_DURATION.seconds.from_now).unlock_expired
    save!
  end

  def unlock
    self.lock = nil
    self.lock_ttl = nil
    save!
  end

  def unlock_expired
    with_lock do
      if !lock_ttl.nil? && lock_ttl >= Time.now.to_i
        self.lock = nil
        self.lock_ttl = nil
        save!
      end
    end
  end

  def update_contents(new_file)
    new_file.class.class_eval { attr_accessor :original_filename }
    new_file.original_filename = file_name
    file.attach(io: new_file, filename: original_filename)
    self.version = version.nil? ? 1 : version + 1
    save
  end

  def editable_image?
    !locked? && %r{^image/#{Regexp.union(Constants::WHITELISTED_IMAGE_TYPES_EDITABLE)}} =~ file.content_type
  end

  def generate_base64(style)
    return convert_variant_to_base64(medium_preview) if style == :medium
  end

  private

  def tempdir
    Rails.root.join('tmp')
  end

  def previewable_image?
    file.blob&.content_type =~ %r{^image/#{Regexp.union(Constants::WHITELISTED_IMAGE_TYPES)}}
  end

  def step_or_result_or_repository_asset_value
    # We must allow both step and result to be blank because of GUI
    # (even though it's not really a "valid" asset)
    if step.present? && result.present? ||
       step.present? && repository_asset_value.present? ||
       result.present? && repository_asset_value.present?
      errors.add(
        :base,
        'Asset can only be result or step or repository cell, not ever.'
      )
    end
  end

  def wopi_filename_valid
    # Check that filename without extension is not blank
    unless file.original_filename[0..-6].present?
      errors.add(
        :file,
        I18n.t('general.text.not_blank')
      )
    end
    # Check maximum filename length
    if file.original_filename.length > Constants::FILENAME_MAX_LENGTH
      errors.add(
        :file,
        I18n.t(
          'general.file.file_name_too_long',
          limit: Constants::FILENAME_MAX_LENGTH
        )
      )
    end
  end
end
