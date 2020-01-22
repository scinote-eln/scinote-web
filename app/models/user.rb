# frozen_string_literal: true

class User < ApplicationRecord
  include SearchableModel
  include SettingsModel
  include VariablesModel
  include User::TeamRoles
  include User::ProjectRoles
  include TeamBySubjectModel
  include InputSanitizeHelper
  include ActiveStorageConcerns

  acts_as_token_authenticatable
  devise :invitable, :confirmable, :database_authenticatable, :registerable,
         :async, :recoverable, :rememberable, :trackable, :validatable,
         :timeoutable, :omniauthable,
         omniauth_providers: Extends::OMNIAUTH_PROVIDERS,
         stretches: Constants::PASSWORD_STRETCH_FACTOR

  has_one_attached :avatar

  # has_attached_file :avatar,
  #                   styles: {
  #                     medium: Constants::MEDIUM_PIC_FORMAT,
  #                     thumb: Constants::THUMB_PIC_FORMAT,
  #                     icon: Constants::ICON_PIC_FORMAT,
  #                     icon_small: Constants::ICON_SMALL_PIC_FORMAT
  #                   },
  #                   default_url: Constants::DEFAULT_AVATAR_URL

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

  # validates_attachment :avatar,
  #   :content_type => { :content_type => ["image/jpeg", "image/png"] },
  #   size: { less_than: Constants::AVATAR_MAX_SIZE_MB.megabyte,
  #           message: I18n.t('client_api.user.avatar_too_big') }
  validate :time_zone_check

  store_accessor :settings, :time_zone, :notifications_settings

  default_settings(
    time_zone: 'UTC',
    date_format: Constants::DEFAULT_DATE_FORMAT,
    notifications_settings: {
      assignments: true,
      assignments_email: false,
      recent: true,
      recent_email: false,
      system_message_email: false
    },
    tooltips_enabled: true
  )

  store_accessor :variables, :export_vars

  default_variables(
    export_vars: {
      num_of_export_all_last_24_hours: 0,
      last_export_timestamp: Time.now.utc.beginning_of_day.to_i
    }
  )

  # Relations
  has_many :user_identities, inverse_of: :user
  has_many :user_teams, inverse_of: :user
  has_many :teams, through: :user_teams
  has_many :user_projects, inverse_of: :user
  has_many :projects, through: :user_projects
  has_many :user_my_modules, inverse_of: :user
  has_many :my_modules, through: :user_my_modules
  has_many :comments, inverse_of: :user
  has_many :activities, inverse_of: :owner, foreign_key: 'owner_id'
  has_many :results, inverse_of: :user
  has_many :samples, inverse_of: :user
  has_many :samples_tables, inverse_of: :user, dependent: :destroy
  has_many :repositories, inverse_of: :user
  has_many :repository_table_states, inverse_of: :user, dependent: :destroy
  has_many :steps, inverse_of: :user
  has_many :custom_fields, inverse_of: :user
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
  has_many :modified_custom_fields,
           class_name: 'CustomField',
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
  has_many :created_sample_groups,
           class_name: 'SampleGroup',
           foreign_key: 'created_by_id'
  has_many :modified_sample_groups,
           class_name: 'SampleGroup',
           foreign_key: 'last_modified_by_id'
  has_many :assigned_sample_my_modules,
           class_name: 'SampleMyModule',
           foreign_key: 'assigned_by_id'
  has_many :created_sample_types,
           class_name: 'SampleType',
           foreign_key: 'created_by_id'
  has_many :modified_sample_types,
           class_name: 'SampleType',
           foreign_key: 'last_modified_by_id'
  has_many :modified_samples,
           class_name: 'Sample',
           foreign_key: 'last_modified_by_id'
  has_many :modified_steps, class_name: 'Step', foreign_key: 'modified_by_id'
  has_many :created_tables, class_name: 'Table', foreign_key: 'created_by_id'
  has_many :modified_tables,
           class_name: 'Table',
           foreign_key: 'last_modified_by_id'
  has_many :created_tags, class_name: 'Tag', foreign_key: 'created_by_id'

  has_many :tokens,
           class_name: 'Token',
           foreign_key: 'user_id',
           inverse_of: :user

  has_many :modified_tags,
           class_name: 'Tag',
           foreign_key: 'last_modified_by_id'
  has_many :assigned_user_my_modules,
           class_name: 'UserMyModule',
           foreign_key: 'assigned_by_id'
  has_many :assigned_user_teams,
           class_name: 'UserTeam',
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

  has_many :user_notifications, inverse_of: :user
  has_many :notifications, through: :user_notifications
  has_many :user_system_notifications, dependent: :destroy
  has_many :system_notifications, through: :user_system_notifications
  has_many :zip_exports, inverse_of: :user, dependent: :destroy
  has_many :datatables_teams, class_name: '::Views::Datatables::DatatablesTeam'
  has_many :view_states, dependent: :destroy

  has_many :access_grants, class_name: 'Doorkeeper::AccessGrant',
                           foreign_key: :resource_owner_id,
                           dependent: :delete_all
  has_many :access_tokens, class_name: 'Doorkeeper::AccessToken',
                           foreign_key: :resource_owner_id,
                           dependent: :delete_all

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

  def self.create_from_omniauth!(auth)
    full_name = "#{auth.info.first_name} #{auth.info.last_name}"
    user = User.new(full_name: full_name,
                    initials: generate_initials(full_name),
                    email: email,
                    password: generate_user_password)
    User.transaction do
      user.save!
      user.user_identities.create!(provider: auth.provider, uid: auth.uid)
      user.update!(confirmed_at: user.created_at)
    end
    user
  end

  # Search all active users for username & email. Can
  # also specify which team to ignore.
  def self.search(
    active_only,
    query = nil,
    team_to_ignore = nil
  )
    result = User.all

    if active_only
      result = result.where.not(confirmed_at: nil)
    end

    if team_to_ignore.present?
      ignored_ids =
        UserTeam
        .select(:user_id)
        .where(team_id: team_to_ignore.id)
      result =
        result
        .where("users.id NOT IN (?)", ignored_ids)
    end

    result
      .where_attributes_like([:full_name, :email], query)
      .distinct
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

  def projects_by_teams(team_id = 0, sort_by = nil, archived = false)
    archived = archived ? true : false
    query = Project.all.joins(:user_projects)
    sql = 'projects.team_id IN (SELECT DISTINCT team_id ' \
          'FROM user_teams WHERE user_teams.user_id = :user_id)'
    if team_id.zero? || !user_teams.find_by(team_id: team_id).try(:admin?)
      # Admins see all projects of team
      sql += ' AND (projects.visibility=1 OR user_projects.user_id=:user_id)'
    end
    sql += ' AND projects.archived = :archived '

    sort =
      case sort_by
      when 'old'
        { created_at: :asc }
      when 'atoz'
        { name: :asc }
      when 'ztoa'
        { name: :desc }
      else
        { created_at: :desc }
      end

    if team_id > 0
      result = query
               .where('projects.team_id = ?', team_id)
               .where(sql, user_id: id, archived: archived)
               .order(sort)
               .distinct
               .group_by(&:team)
    else
      result = query
               .where(sql, user_id: id, archived: archived)
               .order(sort)
               .distinct
               .group_by(&:team)
    end
    result || []
  end

  def projects_tree(team, sort_by = nil)
    result = team.projects.includes(active_experiments: :active_my_modules)
    unless is_admin_of_team?(team)
      # Only admins see all projects of the team
      result = result.joins(:user_projects).where(
        'visibility=1 OR user_projects.user_id=:user_id', user_id: id
      )
    end

    sort = case sort_by
           when 'old'
             { created_at: :asc }
           when 'atoz'
             { name: :asc }
           when 'ztoa'
             { name: :desc }
           else
             { created_at: :desc }
           end
    result.where(archived: false).distinct.order(sort)
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
    User
      .joins('LEFT OUTER JOIN tokens ON user_id = users.id')
      .where(tokens: { token: token })
      .where('tokens.ttl = 0 OR tokens.ttl > ?', Time.now.to_i)
      .first
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
    statistics[:number_of_protocols] =
      added_protocols.where(
        protocol_type: Protocol.protocol_types.slice(
          :in_repository_private,
          :in_repository_public,
          :in_repository_archived
        ).values
      ).count
    statistics
  end

  def self.from_azure_jwt_token(token_payload)
    includes(:user_identities)
      .where(
        'user_identities.provider=? AND user_identities.uid=?',
        Rails.configuration.x.azure_ad_apps[token_payload[:aud]][:provider],
        token_payload[:sub]
      )
      .references(:user_identities)
      .take
  end

  def has_linked_account?(provider)
    user_identities.where(provider: provider).exists?
  end

  # This method must be overwriten for addons that will be installed
  def show_login_system_notification?
    user_system_notifications.show_on_login.present? &&
      (ENV['ENABLE_TUTORIAL'] != 'true' || settings['tutorial_completed'])
  end

  # json friendly attributes
  NOTIFICATIONS_TYPES = %w(assignments_notification recent_notification
                           assignments_email_notification
                           recent_email_notification
                           system_message_email_notification)

  # declare notifications getters
  NOTIFICATIONS_TYPES.each do |name|
    define_method(name) do
      attr_name = name.gsub('_notification', '')
      notifications_settings.fetch(attr_name.to_sym)
    end
  end

  # declare notifications setters
  NOTIFICATIONS_TYPES.each do |name|
    define_method("#{name}=") do |value|
      attr_name = name.gsub('_notification', '').to_sym
      notifications_settings[attr_name] = value
    end
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
    query_teams = teams.pluck(:id)
    query_teams &= filters[:teams].map(&:to_i) if filters[:teams]
    query_teams &= User.team_by_subject(filters[:subjects]) if filters[:subjects]
    User.where(id: UserTeam.where(team_id: query_teams).select(:user_id))
        .search(false, search_query)
        .select(:full_name, :id)
        .map { |i| { label: escape_input(i[:full_name]), value: i[:id] } }
  end

  def file_name
    return '' unless avatar.attached?

    avatar.blob&.filename&.sanitized
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
