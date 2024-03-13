# frozen_string_literal: true

class Asset < ApplicationRecord
  include SearchableModel
  include DatabaseHelper
  include Encryptor
  include WopiUtil
  include ActiveStorageFileUtil
  include ActiveStorageConcerns

  require 'tempfile'
  # Lock duration set to 30 minutes
  LOCK_DURATION = 60 * 30
  SEARCHABLE_ATTRIBUTES = ['active_storage_blobs.filename', 'asset_text_data.data_vector'].freeze

  enum view_mode: { thumbnail: 0, list: 1, inline: 2 }

  # ActiveStorage configuration
  has_one_attached :file
  has_one_attached :file_pdf_preview
  has_one_attached :preview_image

  # Asset validation
  # This could cause some problems if you create empty asset and want to
  # assign it to result
  validate :step_or_result_or_repository_asset_value
  validate :wopi_filename_valid, on: :wopi_file_creation
  validate :check_file_size, on: :on_api_upload

  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :last_modified_by, class_name: 'User', optional: true
  belongs_to :team, optional: true
  has_one :step_asset, inverse_of: :asset, dependent: :destroy
  has_one :step, through: :step_asset, touch: true
  has_one :result_asset, inverse_of: :asset, dependent: :destroy
  has_one :result, through: :result_asset, touch: true
  has_one :repository_asset_value, inverse_of: :asset, dependent: :destroy
  has_one :repository_cell, through: :repository_asset_value
  has_many :report_elements, inverse_of: :asset, dependent: :destroy
  has_one :asset_text_datum, inverse_of: :asset, dependent: :destroy
  has_many :asset_sync_tokens, dependent: :destroy

  scope :sort_assets, lambda { |sort_value = 'new'|
    sort = case sort_value
           when 'old' then { created_at: :asc }
           when 'atoz' then { 'active_storage_blobs.filename': :asc }
           when 'ztoa' then { 'active_storage_blobs.filename': :desc }
           else { created_at: :desc }
           end

    joins(file_attachment: :blob).order(sort)
  }

  attr_accessor :file_content, :file_info

  before_save :reset_file_processing, if: -> { file.new_record? }

  def self.search(
    user,
    include_archived,
    query = nil,
    current_team = nil,
    options = {}
  )

    teams = options[:teams] || current_team || user.teams.select(:id)

    assets_in_steps = Asset.joins(:step)
                           .where(steps: { protocol: Protocol.search(user, include_archived, nil, teams) })
                           .pluck(:id)

    assets_in_results = Asset.joins(:result)
                             .where(results: { id: Result.search(user, include_archived, nil, teams) })
                             .pluck(:id)

    assets_in_inventories = Asset.joins(repository_cell: { repository_column: :repository })
                                 .where(repositories: { team: teams })
                                 .where.not(repositories: { type: 'RepositorySnapshot' })
                                 .pluck(:id)

    assets = distinct.where('assets.id IN (?) OR assets.id IN (?) OR assets.id IN (?)',
                            assets_in_steps, assets_in_results, assets_in_inventories)

    Asset.left_outer_joins(:asset_text_datum)
         .joins(file_attachment: :blob)
         .from(assets, 'assets')
         .where_attributes_like_boolean(SEARCHABLE_ATTRIBUTES, query, options)
  end

  def blob
    file&.blob
  end

  def previewable?
    return false unless preview_image.attached? || file.attached?

    previewable_document?(blob) || previewable_image?
  end

  def preview_attachment
    preview_image.attached? ? preview_image : file
  end

  def medium_preview
    preview_attachment.representation(resize_to_limit: Constants::MEDIUM_PIC_FORMAT)
  end

  def large_preview
    preview_attachment.representation(resize_to_limit: Constants::LARGE_PIC_FORMAT)
  end

  def file_name
    return '' unless file.attached?

    file.blob&.filename&.sanitized
  end

  def preview_image_file_name
    return '' unless preview_image.attached?

    preview_image.blob&.filename&.sanitized
  end

  def render_file_name
    if file.attached? && file.metadata['asset_type']
      file.metadata['name']
    else
      file_name
    end
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

    duplicate_file(new_asset)
    new_asset
  end

  def duplicate_file(to_asset)
    return unless file.attached?

    raise ArgumentError, 'Destination asset should be persisted first!' unless to_asset.persisted?

    file.blob.open do |tmp_file|
      to_blob = ActiveStorage::Blob.create_and_upload!(io: tmp_file, filename: blob.filename)
      to_asset.file.attach(to_blob)
    end

    if preview_image.attached?
      preview_image.blob.open do |tmp_preview_image|
        to_blob = ActiveStorage::Blob.create_and_upload!(
          io: tmp_preview_image,
          filename: blob.filename,
          metadata: blob.metadata
        )
        to_asset.preview_image.attach(to_blob)
      end
    end

    to_asset.post_process_file
  end

  def image?
    content_type =~ %r{^image/#{Regexp.union(Constants::WHITELISTED_IMAGE_TYPES)}}
  end

  def text?
    Constants::TEXT_EXTRACT_FILE_TYPES.any? do |v|
      file&.blob&.content_type&.start_with? v
    end
  end

  def marvinjs?
    file.metadata[:asset_type] == 'marvinjs'
  end

  def pdf_preview_ready?
    return false if pdf_preview_processing

    return true if file_pdf_preview.attached?

    PdfPreviewJob.perform_later(id)
    ActiveRecord::Base.no_touching { update(pdf_preview_processing: true) }
    false
  end

  def pdf?
    content_type == 'application/pdf'
  end

  def pdf_previewable?
    pdf? || (previewable_document?(blob) && Rails.application.config.x.enable_pdf_previews)
  end

  def post_process_file
    # Update asset's estimated size immediately
    update_estimated_size unless text? || marvinjs?

    if Rails.application.config.x.enable_pdf_previews && previewable_document?(blob)
      PdfPreviewJob.perform_later(id)
      ActiveRecord::Base.no_touching { update(pdf_preview_processing: true) }
    end
  end

  # If team is provided, its space_taken
  # is updated as well
  def update_estimated_size
    return if file_size.blank?

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
    file_ext = file_name.split('.').last&.downcase
    action = get_action(file_ext, action)
    if !action.nil?
      action_url = action[:urlsrc]
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
    action[:icon] if action[:icon]
  end

  # locked?, lock_asset and refresh_lock rely on the asset
  # being locked in the database to prevent race conditions
  def locked?
    unlock_expired
    !lock.nil?
  end

  def lock_asset(lock_string)
    self.lock = lock_string
    self.lock_ttl = Time.now.to_i + LOCK_DURATION
    save!
  end

  def refresh_lock
    self.lock_ttl = Time.now.to_i + LOCK_DURATION
    save!
  end

  def unlock
    self.lock = nil
    self.lock_ttl = nil
    save!
  end

  def unlock_expired
    with_lock do
      if !lock_ttl.nil? && lock_ttl < Time.now.to_i
        self.lock = nil
        self.lock_ttl = nil
        save!
      end
    end
  end

  def update_contents(new_file)
    file.attach(io: new_file, filename: file_name)
    self.version = version.nil? ? 1 : version + 1
    save
  end

  def editable_image?
    !locked? && (%r{^image/#{Regexp.union(Constants::WHITELISTED_IMAGE_TYPES_EDITABLE)}} =~ file.content_type).present?
  end

  def generate_base64(style)
    return convert_variant_to_base64(medium_preview) if style == :medium
  end

  def my_module
    (result || step)&.my_module
  end

  def parent
    step || result || repository_cell
  end

  def rename_file(new_name)
    if file.attached?
      asset_type = file.metadata['asset_type']
      new_filename = case asset_type
                     when 'marvinjs'
                       "#{new_name}.jpg"
                     when 'gene_sequence'
                       "#{new_name}.json"
                     else
                       new_name
                     end

      updated_metadata = file.blob.metadata.merge('name' => new_name)

      if %w(marvinjs gene_sequence).include?(asset_type)
        file.blob.update!(
          filename: new_filename,
          metadata: updated_metadata
        )
      else
        file.blob.update!(filename: new_filename)
      end

      if asset_type == 'gene_sequence' && preview_image.attached?
        new_image_filename = "#{new_name}.png"
        preview_image.blob.update!(filename: new_image_filename)
      end
    end
  end

  private

  def tempdir
    Rails.root.join('tmp')
  end

  def previewable_image?
    preview_image.attached? ||
      file.blob&.content_type&.match?(%r{^image/#{Regexp.union(Constants::WHITELISTED_IMAGE_TYPES)}})
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
    if file_name[0..-6].blank?
      errors.add(
        :file,
        I18n.t('general.text.not_blank')
      )
    end
    # Check maximum filename length
    if file_name.length > Constants::FILENAME_MAX_LENGTH
      errors.add(
        :file,
        I18n.t(
          'general.file.file_name_too_long',
          limit: Constants::FILENAME_MAX_LENGTH
        )
      )
    end
  end

  def check_file_size
    if file.attached?
      if file.blob.byte_size > Rails.application.config.x.file_max_size_mb.megabytes
        errors.add(:file, I18n.t('activerecord.errors.models.asset.attributes.file.too_big'))
      end
    end
  end

  def reset_file_processing
    self.file_processing = false
  end
end
