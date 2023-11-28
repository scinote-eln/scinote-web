# frozen_string_literal: true

class User < ApplicationRecord
  include SearchableModel
  include SettingsModel
  include VariablesModel
  include InputSanitizeHelper
  include ActiveStorageConcerns

  devise :invitable, :confirmable, :database_authenticatable, :registerable,
         :async, :recoverable, :rememberable, :trackable, :validatable,
         :timeoutable, :omniauthable, :lockable,
         omniauth_providers: Extends::OMNIAUTH_PROVIDERS,
         stretches: Constants::PASSWORD_STRETCH_FACTOR

  has_one_attached :avatar

  auto_strip_attributes :full_name, :initials, nullify: false
  validates :full_name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :initials,
            presence: true,
            length: { maximum: Constants::USER_INITIALS_MAX_LENGTH }
  validates :email,
            presence: true,
            length: { maximum: Constants::EMAIL_MAX_LENGTH }

  validate :time_zone_check

  validates :external_id, length: { maximum: Constants::EMAIL_MAX_LENGTH }

  store_accessor :settings, :time_zone, :notifications_settings, :external_id

  DEFAULT_SETTINGS = {
    time_zone: 'UTC',
    date_format: Constants::DEFAULT_DATE_FORMAT,
    notifications_settings: {
      assignments: true,
      assignments_email: false,
      recent: true,
      recent_email: false,
      system_message_email: false
    }.merge(Extends::DEFAULT_USER_NOTIFICATION_SETTINGS)
  }.freeze

  DEFAULT_OTP_DRIFT_TIME_SECONDS = 10

  store_accessor :variables, :export_vars

  default_variables(
    export_vars: {
      num_of_export_all_last_24_hours: 0,
      last_export_timestamp: Time.now.utc.beginning_of_day.to_i
    }
  )

  # Relations
  has_many :user_identities, inverse_of: :user
  has_many :user_assignments, dependent: :destroy
  has_many :user_projects, inverse_of: :user
  has_many :teams, through: :user_assignments, source: :assignable, source_type: 'Team'
  has_many :projects, through: :user_assignments, source: :assignable, source_type: 'Project'
  has_many :user_my_modules, inverse_of: :user
  has_many :my_modules, through: :user_assignments, source: :assignable, source_type: 'MyModule'
  has_many :comments, inverse_of: :user
  has_many :activities, inverse_of: :owner, foreign_key: 'owner_id'
  has_many :results, inverse_of: :user
  has_many :repositories, inverse_of: :user
  has_many :repository_table_states, inverse_of: :user, dependent: :destroy
  has_many :repository_table_filters, foreign_key: 'created_by_id', inverse_of: :created_by, dependent: :nullify
  has_many :steps, inverse_of: :user
  has_many :reports, inverse_of: :user
  has_many :created_assets, class_name: 'Asset', foreign_key: 'created_by_id'
  has_many :modified_assets,
           class_name: 'Asset',
           foreign_key: 'last_modified_by_id'
  has_many :created_checklists,
           class_name: 'Checklist',
           foreign_key: 'created_by_id'
  has_many :modified_checklists,
           class_name: 'Checklist',
           foreign_key: 'last_modified_by_id'
  has_many :created_checklist_items,
           class_name: 'ChecklistItem',
           foreign_key: 'created_by_id'
  has_many :modified_checklist_items,
           class_name: 'ChecklistItem',
           foreign_key: 'last_modified_by_id'
  has_many :modified_comments,
           class_name: 'Comment',
           foreign_key: 'last_modified_by_id'
  has_many :created_my_module_groups,
           class_name: 'MyModuleGroup',
           foreign_key: 'created_by_id'
  has_many :created_my_module_tags,
           class_name: 'MyModuleTag',
           foreign_key: 'created_by_id'
  has_many :created_my_modules,
           class_name: 'MyModule',
           foreign_key: 'created_by_id'
  has_many :modified_my_modules,
           class_name: 'MyModule',
           foreign_key: 'last_modified_by_id'
  has_many :archived_my_modules,
           class_name: 'MyModule',
           foreign_key: 'archived_by_id'
  has_many :restored_my_modules,
           class_name: 'MyModule',
           foreign_key: 'restored_by_id'
  has_many :created_teams,
           class_name: 'Team',
           foreign_key: 'created_by_id'
  has_many :modified_teams,
           class_name: 'Team',
           foreign_key: 'last_modified_by_id'
  has_many :created_projects,
           class_name: 'Project',
           foreign_key: 'created_by_id'
  has_many :modified_projects,
           class_name: 'Project',
           foreign_key: 'last_modified_by_id'
  has_many :archived_projects,
           class_name: 'Project',
           foreign_key: 'archived_by_id'
  has_many :restored_projects,
           class_name: 'Project',
           foreign_key: 'restored_by_id'
  has_many :archived_project_folders,
           class_name: 'ProjectFolder',
           foreign_key: 'archived_by_id',
           inverse_of: :arhived_by
  has_many :restored_project_folders,
           class_name: 'ProjectFolder',
           foreign_key: 'restored_by_id',
           inverse_of: :restored_by
  has_many :modified_reports,
           class_name: 'Report',
           foreign_key: 'last_modified_by_id'
  has_many :modified_results,
           class_name: 'Result',
           foreign_key: 'modified_by_id'
  has_many :archived_results,
           class_name: 'Result',
           foreign_key: 'archived_by_id'
  has_many :restored_results,
           class_name: 'Result',
           foreign_key: 'restored_by_id'
  has_many :modified_steps, class_name: 'Step', foreign_key: 'modified_by_id'
  has_many :created_tables, class_name: 'Table', foreign_key: 'created_by_id'
  has_many :modified_tables,
           class_name: 'Table',
           foreign_key: 'last_modified_by_id'
  has_many :created_tags, class_name: 'Tag', foreign_key: 'created_by_id'

  has_many :tokens,
           class_name: 'Token',
           inverse_of: :user,
           dependent: :destroy

  has_many :modified_tags,
           class_name: 'Tag',
           foreign_key: 'last_modified_by_id'
  has_many :assigned_user_my_modules,
           class_name: 'UserMyModule',
           foreign_key: 'assigned_by_id'
  has_many :assigned_user_projects,
           class_name: 'UserProject',
           foreign_key: 'assigned_by_id'
  has_many :added_protocols,
           class_name: 'Protocol',
           foreign_key: 'added_by_id',
           inverse_of: :added_by
  has_many :archived_protocols,
           class_name: 'Protocol',
           foreign_key: 'archived_by_id',
           inverse_of: :archived_by
  has_many :restored_protocols,
           class_name: 'Protocol',
           foreign_key: 'restored_by_id',
           inverse_of: :restored_by
  has_many :published_protocols,
           class_name: 'Protocol',
           foreign_key: 'published_by_id',
           inverse_of: :published_by,
           dependent: :nullify
  has_many :archived_repositories,
           class_name: 'Repository',
           foreign_key: 'archived_by_id',
           inverse_of: :archived_by,
           dependent: :nullify
  has_many :restored_repositories,
           class_name: 'Repository',
           foreign_key: 'restored_by_id',
           inverse_of: :restored_by,
           dependent: :nullify
  has_many :created_repository_rows,
           class_name: 'RepositoryRow',
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :nullify
  has_many :archived_repository_rows,
           class_name: 'RepositoryRow',
           foreign_key: 'archived_by_id',
           inverse_of: :archived_by,
           dependent: :nullify
  has_many :restored_repository_rows,
           class_name: 'RepositoryRow',
           foreign_key: 'restored_by_id',
           inverse_of: :restored_by,
           dependent: :nullify
  has_many :assigned_my_module_repository_rows,
           class_name: 'MyModuleRepositoryRow',
           foreign_key: 'assigned_by_id'
  has_many :created_repository_status_types,
           class_name: 'RepositoryStatusItem',
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :nullify
  has_many :modified_repository_status_types,
           class_name: 'RepositoryStatusItem',
           foreign_key: 'last_modified_by_id',
           inverse_of: :last_modified_by,
           dependent: :nullify
  has_many :created_repository_status_value,
           class_name: 'RepositoryStatusValue',
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :nullify
  has_many :modified_repository_status_value,
           class_name: 'RepositoryStatusValue',
           foreign_key: 'last_modified_by_id',
           inverse_of: :last_modified_by,
           dependent: :nullify
  has_many :created_repository_date_time_values,
           class_name: 'RepositoryDateTimeValue',
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :nullify
  has_many :modified_repository_date_time_values,
           class_name: 'RepositoryDateTimeValue',
           foreign_key: 'last_modified_by_id',
           inverse_of: :last_modified_by,
           dependent: :nullify
  has_many :created_repository_checklist_values,
           class_name: 'RepositoryChecklistValue',
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :nullify
  has_many :modified_repository_checklist_values,
           class_name: 'RepositoryChecklistValue',
           foreign_key: 'last_modified_by_id',
           inverse_of: :last_modified_by,
           dependent: :nullify
  has_many :created_repository_stock_value,
           class_name: 'RepositoryStockValue',
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :nullify
  has_many :modified_repository_stock_value,
           class_name: 'RepositoryStockValue',
           foreign_key: 'created_by_id',
           inverse_of: :last_modified_by,
           dependent: :nullify
  has_many :created_repository_checklist_types,
           class_name: 'RepositoryChecklistItem',
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :nullify
  has_many :modified_repository_checklist_types,
           class_name: 'RepositoryChecklistItem',
           foreign_key: 'last_modified_by_id',
           inverse_of: :last_modified_by,
           dependent: :nullify
  has_many :created_repository_number_values,
           class_name: 'RepositoryNumberValue',
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :nullify
  has_many :modified_repository_number_values,
           class_name: 'RepositoryNumberValue',
           foreign_key: 'last_modified_by_id',
           inverse_of: :last_modified_by,
           dependent: :nullify
  has_many :created_repository_text_values,
           class_name: 'RepositoryTextValue',
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :nullify
  has_many :modified_repository_text_values,
           class_name: 'RepositoryTextValue',
           foreign_key: 'last_modified_by_id',
           inverse_of: :last_modified_by,
           dependent: :nullify
  has_many :created_repository_stock_values,
           class_name: 'RepositoryStockValue',
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :nullify
  has_many :modified_repository_stock_values,
           class_name: 'RepositoryStockValue',
           foreign_key: 'last_modified_by_id',
           inverse_of: :last_modified_by,
           dependent: :nullify
  has_many :shareable_links,
           foreign_key: 'created_by_id',
           inverse_of: :created_by,
           dependent: :destroy

  has_many :notifications, as: :recipient, dependent: :destroy, inverse_of: :recipient
  has_many :zip_exports, inverse_of: :user, dependent: :destroy
  has_many :view_states, dependent: :destroy

  has_many :access_grants, class_name: 'Doorkeeper::AccessGrant',
                           foreign_key: :resource_owner_id,
                           dependent: :delete_all
  has_many :access_tokens, class_name: 'Doorkeeper::AccessToken',
                           foreign_key: :resource_owner_id,
                           dependent: :delete_all

  has_many :hidden_repository_cell_reminders, dependent: :destroy

  before_validation :downcase_email!
  before_destroy :destroy_notifications

  def name
    full_name
  end

  def name=(name)
    self.full_name = name
  end

  def avatar_remote_url=(url_value)
    self.avatar = URI.parse(url_value)
    # Assuming url_value is http://example.com/photos/face.png
    # avatar.filename == "face.png"
    # avatar.content_type == "image/png"
    @avatar_remote_url = url_value
  end

  def avatar_variant(style)
    return Constants::DEFAULT_AVATAR_URL.gsub(':style', style.to_s) unless avatar.attached?

    format = case style.to_sym
             when :medium
               Constants::MEDIUM_PIC_FORMAT
             when :thumb
               Constants::THUMB_PIC_FORMAT
             when :icon
               Constants::ICON_PIC_FORMAT
             when :icon_small
               Constants::ICON_SMALL_PIC_FORMAT
             else
               Constants::ICON_SMALL_PIC_FORMAT
             end
    avatar.variant(resize_to_limit: format)
  end

  def avatar_url(style)
    Rails.application.routes.url_helpers.url_for(avatar_variant(style))
  end

  def date_format
    settings[:date_format] || Constants::DEFAULT_DATE_FORMAT
  end

  def date_format=(date_format)
    return if settings[:date_format] == date_format
    if Constants::SUPPORTED_DATE_FORMATS.include?(date_format)
      settings[:date_format] = date_format
      clear_view_cache
    end
  end

  def current_team
    Team.find_by_id(self.current_team_id)
  end

  def permission_team=(team)
    @permission_team = teams.find_by(id: team.id)
  end

  def permission_team
    @permission_team || current_team
  end

  def self.from_omniauth(auth)
    includes(:user_identities)
      .where(
        'user_identities.provider=? AND user_identities.uid=?',
        auth.provider,
        auth.uid
      )
      .references(:user_identities)
      .take
  end

  def member_of_team?(team)
    team.user_assignments.exists?(user: self)
  end

  # Search all active users for username & email. Can
  # also specify which team to ignore.
  def self.search(
    active_only,
    query = nil,
    team_to_ignore = nil
  )
    result = User.all
    result = result.where.not(confirmed_at: nil) if active_only

    if team_to_ignore.present?
      ignored_ids = UserAssignment.select(:user_id).where(assignable: team_to_ignore)
      result = result.where.not(users: { id: ignored_ids })
    end

    result.where_attributes_like(%i(full_name email), query).distinct
  end

  # Whether user is active (= confirmed) or not
  def active?
    confirmed_at.present?
  end

  def active_status_str
    if active?
      I18n.t('users.enums.status.active')
    else
      I18n.t('users.enums.status.pending')
    end
  end

  # Finds all activities of user that is assigned to project. If user
  # is not an owner of the project, user must be also assigned to
  # module.
  def last_activities
    Activity
      .joins(project: :user_projects)
      .joins(
        'LEFT OUTER JOIN my_modules ON activities.my_module_id = my_modules.id'
      )
      .joins(
        'LEFT OUTER JOIN user_my_modules ON my_modules.id = ' \
        'user_my_modules.my_module_id'
      )
      .where(user_projects: { user_id: self })
      .where(
        'activities.my_module_id IS NULL OR ' \
        'user_projects.role = 0 OR ' \
        'user_my_modules.user_id = ?',
        id
      )
      .order(created_at: :desc)
  end

  def self.find_by_valid_wopi_token(token)
    Rails.logger.warn "WOPI: searching by token #{token}"
    User.joins(:tokens)
        .where(tokens: { token: token })
        .find_by('tokens.ttl = 0 OR tokens.ttl > ?', Time.now.to_i)
  end

  def get_wopi_token
    # WOPI does not have a good way to request a new token,
    # so a new token should be provided each time this is called,
    # while keeping any old tokens as long as they have not yet expired
    tokens = Token.where(user_id: id).distinct

    tokens.each do |token|
      token.delete if token.ttl < Time.now.to_i
    end

    token_string =  "#{Devise.friendly_token(20)}-#{id}"
    # WOPI uses millisecond TTLs
    ttl = (Time.now + 1.day).to_i
    wopi_token = Token.create(token: token_string, ttl: ttl, user_id: id)
    Rails.logger.warn("WOPI: generating new token #{wopi_token.token}")
    wopi_token
  end

  def teams_ids
    teams.pluck(:id)
  end

  # Returns a hash with user statistics
  def statistics
    statistics = {}
    statistics[:number_of_teams] = teams.count
    statistics[:number_of_projects] = projects.count
    number_of_experiments = 0
    projects.find_each do |pr|
      number_of_experiments += pr.experiments.count
    end
    statistics[:number_of_experiments] = number_of_experiments
    statistics[:number_of_protocols] = added_protocols.where(
      "(protocol_type=#{Protocol.protocol_types[:in_repository_published_original]}
       OR protocol_type=#{Protocol.protocol_types[:in_repository_draft]}) AND protocols.parent_id IS NULL"
    ).count
    statistics
  end

  def self.from_azure_jwt_token(token_payload)
    settings = ApplicationSettings.instance
    provider_conf = settings.values['azure_ad_apps']&.find { |v| v['app_id'] == token_payload[:aud] }
    return nil unless provider_conf

    joins(:user_identities)
      .find_by(user_identities: { provider: provider_conf['provider_name'], uid: token_payload[:sub] })
  end

  def has_linked_account?(provider)
    user_identities.exists?(provider: provider)
  end

  def increase_daily_exports_counter!
    range = Time.now.utc.beginning_of_day.to_i..Time.now.utc.end_of_day.to_i
    last_export = export_vars[:last_export_timestamp] || 0
    export_vars[:num_of_export_all_last_24_hours] ||= 0

    if range.cover?(last_export)
      export_vars[:num_of_export_all_last_24_hours] += 1
    else
      export_vars[:num_of_export_all_last_24_hours] = 1
    end
    export_vars[:last_export_timestamp] = Time.now.utc.to_i
    save
  end

  def has_available_exports?
    last_export_timestamp = export_vars[:last_export_timestamp] || 0

    # limit 0 means unlimited exports
    return true if TeamZipExport.exports_limit.zero? || last_export_timestamp < Time.now.utc.beginning_of_day.to_i

    exports_left.positive?
  end

  def exports_left
    if (export_vars[:last_export_timestamp] || 0) < Time.now.utc.beginning_of_day.to_i
      return TeamZipExport.exports_limit
    end

    TeamZipExport.exports_limit - export_vars[:num_of_export_all_last_24_hours]
  end

  def global_activity_filter(filters, search_query)
    query_teams = teams
    query_teams = query_teams.where(id: filters[:teams].map(&:to_i)) if filters[:teams].present?
    query_teams = query_teams.by_activity_subjects(filters[:subjects]) if filters[:subjects].present?
    User.where(id: UserAssignment.where(assignable_id: query_teams, assignable_type: 'Team').select(:user_id))
        .search(false, search_query)
  end

  def file_name
    return '' unless avatar.attached?

    avatar.blob&.filename&.sanitized
  end

  def valid_otp?(otp)
    raise StandardError, 'Missing otp_secret' unless otp_secret

    totp = ROTP::TOTP.new(otp_secret, issuer: 'sciNote')
    totp.verify(
      otp,
      drift_behind: ENV.fetch('OTP_DRIFT_TIME_SECONDS', DEFAULT_OTP_DRIFT_TIME_SECONDS).to_i
    )
  end

  def assign_2fa_token!
    self.otp_secret = ROTP::Base32.random
    save!
  end

  def enable_2fa!
    recovery_codes = []
    Constants::TWO_FACTOR_RECOVERY_CODE_COUNT.times do
      recovery_codes.push(SecureRandom.hex(Constants::TWO_FACTOR_RECOVERY_CODE_LENGTH / 2))
    end

    update!(
      two_factor_auth_enabled: true,
      otp_recovery_codes: recovery_codes.map { |c| Devise::Encryptor.digest(self.class, c) }
    )

    recovery_codes
  end

  def disable_2fa!
    update!(two_factor_auth_enabled: false, otp_secret: nil, otp_recovery_codes: nil)
  end

  def recover_2fa!(code)
    return unless otp_recovery_codes

    otp_recovery_codes.each do |recovery_code|
      if Devise::Encryptor.compare(self.class, recovery_code, code)
        update!(otp_recovery_codes: otp_recovery_codes.reject { |i| i == recovery_code })
        return true
      end
    end
    false
  end

  def after_database_authentication
    if Rails.application.config.x.disable_local_passwords
      throw(:warden, message: I18n.t('devise.failure.auth_method_disabled'))
    end
  end

  def my_module_visible_table_columns
    settings['visible_my_module_table_columns'].presence ||
      %w(id due_date age results status archived assigned tags comments)
  end

  protected

  def confirmation_required?
    Rails.configuration.x.enable_email_confirmations
  end

  def time_zone_check
    if time_zone.nil? ||
       ActiveSupport::TimeZone.new(time_zone).nil?
      errors.add(:time_zone)
    end
  end

  private

  def downcase_email!
    return unless email

    self.email = email.downcase
  end

  def destroy_notifications
    # Find all notifications where user is the only reference
    # on the notification, and destroy all such notifications
    # (user_notifications are destroyed when notification is
    # destroyed). We try to do this efficiently (hence in_groups_of).
    nids_all = notifications.pluck(:id)
    nids_all.in_groups_of(1000, false) do |nids|
      Notification
        .where(id: nids)
        .joins(:user_notifications)
        .group('notifications.id')
        .having('count(notification_id) <= 1')
        .destroy_all
    end

    # Now, simply destroy all user notification relations left
    user_notifications.destroy_all
  end

  def clear_view_cache
    Rails.cache.delete_matched(%r{^views\/users\/#{id}-})
  end
end
