class User < ActiveRecord::Base
  include SearchableModel

  devise :invitable, :confirmable, :database_authenticatable, :registerable, :async,
    :recoverable, :rememberable, :trackable, :validatable, stretches: 10
  has_attached_file :avatar, :styles => {
    :medium => "300x300>",
    :thumb => "100x100>",
    :icon => "40x40>",
    :icon_small => "30x30>"
  },
  :default_url => "/images/:style/missing.png"

  enum tutorial_status: {
    no_tutorial_done: 0,
    intro_tutorial_done: 1
  }

  auto_strip_attributes :full_name, :initials, nullify: false
  validates :full_name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :initials,
            presence: true,
            length: { maximum: USER_INITIALS_MAX_LENGTH }
  validates :email, presence: true, length: { maximum: EMAIL_MAX_LENGTH }

  validates_attachment :avatar,
    :content_type => { :content_type => ["image/jpeg", "image/png"] },
    size: { less_than: AVATAR_MAX_SIZE.megabytes }
  validates :time_zone, presence: true
  validate :time_zone_check

  # Relations
  has_many :user_organizations, inverse_of: :user
  has_many :organizations, through: :user_organizations
  has_many :user_projects, inverse_of: :user
  has_many :projects, through: :user_projects
  has_many :user_my_modules, inverse_of: :user
  has_many :my_modules, through: :user_my_modules
  has_many :comments, inverse_of: :user
  has_many :activities, inverse_of: :user
  has_many :results, inverse_of: :user
  has_many :samples, inverse_of: :user
  has_many :steps, inverse_of: :user
  has_many :custom_fields, inverse_of: :user
  has_many :reports, inverse_of: :user
  has_many :created_assets, class_name: 'Asset', foreign_key: 'created_by_id'
  has_many :modified_assets, class_name: 'Asset', foreign_key: 'last_modified_by_id'
  has_many :created_checklists, class_name: 'Checklist', foreign_key: 'created_by_id'
  has_many :modified_checklists, class_name: 'Checklist', foreign_key: 'last_modified_by_id'
  has_many :created_checklist_items, class_name: 'ChecklistItem', foreign_key: 'created_by_id'
  has_many :modified_checklist_items, class_name: 'ChecklistItem', foreign_key: 'last_modified_by_id'
  has_many :modified_comments, class_name: 'Comment', foreign_key: 'last_modified_by_id'
  has_many :modified_custom_fields, class_name: 'CustomField', foreign_key: 'last_modified_by_id'
  has_many :created_my_module_groups, class_name: 'MyModuleGroup', foreign_key: 'created_by_id'
  has_many :created_my_module_tags, class_name: 'MyModuleTag', foreign_key: 'created_by_id'
  has_many :created_my_modules, class_name: 'MyModule', foreign_key: 'created_by_id'
  has_many :modified_my_modules, class_name: 'MyModule', foreign_key: 'last_modified_by_id'
  has_many :archived_my_modules, class_name: 'MyModule', foreign_key: 'archived_by_id'
  has_many :restored_my_modules, class_name: 'MyModule', foreign_key: 'restored_by_id'
  has_many :created_organizations, class_name: 'Organization', foreign_key: 'created_by_id'
  has_many :modified_organizations, class_name: 'Organization', foreign_key: 'last_modified_by_id'
  has_many :created_projects, class_name: 'Project', foreign_key: 'created_by_id'
  has_many :modified_projects, class_name: 'Project', foreign_key: 'last_modified_by_id'
  has_many :archived_projects, class_name: 'Project', foreign_key: 'archived_by_id'
  has_many :restored_projects, class_name: 'Project', foreign_key: 'restored_by_id'
  has_many :modified_reports, class_name: 'Report', foreign_key: 'last_modified_by_id'
  has_many :modified_results, class_name: 'Result', foreign_key: 'modified_by_id'
  has_many :archived_results, class_name: 'Result', foreign_key: 'archived_by_id'
  has_many :restored_results, class_name: 'Result', foreign_key: 'restored_by_id'
  has_many :created_sample_groups, class_name: 'SampleGroup', foreign_key: 'created_by_id'
  has_many :modified_sample_groups, class_name: 'SampleGroup', foreign_key: 'last_modified_by_id'
  has_many :assigned_sample_my_modules, class_name: 'SampleMyModule', foreign_key: 'assigned_by_id'
  has_many :created_sample_types, class_name: 'SampleType', foreign_key: 'created_by_id'
  has_many :modified_sample_types, class_name: 'SampleType', foreign_key: 'last_modified_by_id'
  has_many :modified_samples, class_name: 'Sample', foreign_key: 'last_modified_by_id'
  has_many :modified_steps, class_name: 'Step', foreign_key: 'modified_by_id'
  has_many :created_tables, class_name: 'Table', foreign_key: 'created_by_id'
  has_many :modified_tables, class_name: 'Table', foreign_key: 'last_modified_by_id'
  has_many :created_tags, class_name: 'Tag', foreign_key: 'created_by_id'
  has_many :modified_tags, class_name: 'Tag', foreign_key: 'last_modified_by_id'
  has_many :assigned_user_my_modules, class_name: 'UserMyModule', foreign_key: 'assigned_by_id'
  has_many :assigned_user_organizations, class_name: 'UserOrganization', foreign_key: 'assigned_by_id'
  has_many :assigned_user_projects, class_name: 'UserProject', foreign_key: 'assigned_by_id'
  has_many :added_protocols, class_name: 'Protocol', foreign_key: 'added_by_id', inverse_of: :added_by
  has_many :archived_protocols, class_name: 'Protocol', foreign_key: 'archived_by_id', inverse_of: :archived_by
  has_many :restored_protocols, class_name: 'Protocol', foreign_key: 'restored_by_id', inverse_of: :restored_by

  # If other errors besides parameter "avatar" exist,
  # they will propagate to "avatar" also, so remove them
  # and put all other (more specific ones) in it
  after_validation :filter_paperclip_errors

  def name
    full_name
  end

  def name=(name)
    full_name = name
  end

  # Search all active users for username & email. Can
  # also specify which organization to ignore.
  def self.search(
    active_only,
    query = nil,
    organization_to_ignore = nil
  )
    result = User.all

    if active_only
      result = result.where.not(confirmed_at: nil)
    end

    if organization_to_ignore.present?
      ignored_ids =
        UserOrganization
        .select(:user_id)
        .where(organization_id: organization_to_ignore.id)
      result =
        result
        .where("users.id NOT IN (?)", ignored_ids)
    end

    result
    .where_attributes_like([:full_name, :email], query)
    .distinct
  end

  # Search all active users inside given organization for
  # username & email.
  def self.organization_search(
    active_only,
    query = nil,
    organization = nil
  )

    if !organization.present?
      result = nil
    else

      result = User.all

      if active_only
        result = result.where.not(confirmed_at: nil)
      end

      ignored_ids =
        UserOrganization
        .select(:user_id)
        .where(organization_id: organization.id)
      result =
        result
        .where("users.id IN (?)", ignored_ids)

      result
      .where_attributes_like([:full_name, :email], query)
      .distinct
    end
  end


  def empty_avatar(name, size)
    file_ext = name.split(".").last
    self.avatar_file_name = name
    self.avatar_content_type = Rack::Mime.mime_type(".#{file_ext}")
    self.avatar_file_size = size.to_i
  end

  def filter_paperclip_errors
    if errors.key? :avatar
      errors.delete(:avatar)
      messages = []
      errors.each do |attribute|
        errors.full_messages_for(attribute).each do |message|
          messages << message.split(' ').drop(1).join(' ')
        end
      end
      errors.clear
      errors.set(:avatar, messages)
    end
  end

  # Whether user is active (= confirmed) or not
  def active?
    confirmed_at.present?
  end

  def active_status_str
    if active?
      I18n.t("users.enums.status.active")
    else
      I18n.t("users.enums.status.pending")
    end
  end

  def projects_by_orgs(org_id = 0, sort_by = nil, archived = false)
    archived = archived ? true : false
    query = Project.all.joins(:user_projects);
    sql = "projects.organization_id IN " +
          "(SELECT DISTINCT organization_id FROM user_organizations WHERE user_organizations.user_id = ?) " +
          "AND (projects.visibility=1 OR user_projects.user_id=?) " +
          "AND projects.archived = ? ";

    case sort_by
    when "old"
      sort = {created_at: :asc}
    when "atoz"
      sort = {name: :asc}
    when "ztoa"
      sort = {name: :desc}
    else
      sort = {created_at: :desc}
    end

    if org_id > 0
      result = query
        .where("projects.organization_id = ?", org_id)
        .where(sql, id, id, archived)
        .order(sort)
        .distinct
        .group_by { |project| project.organization }
    else
      result = query
        .where(sql, id, id, archived)
        .order(sort)
        .distinct
        .group_by { |project| project.organization }
    end
    result || []
  end

  # Finds all activities of user that is assigned to project. If user
  # is not an owner of the project, user must be also assigned to
  # module.
  def last_activities(last_activity_id = nil, per_page = 10)
    # TODO replace with some kind of Infinity value
    last_activity_id = 999999999999999999999999 if last_activity_id < 1
    Activity
      .joins(project: :user_projects)
      .joins("LEFT OUTER JOIN my_modules ON activities.my_module_id = my_modules.id")
      .joins("LEFT OUTER JOIN user_my_modules ON my_modules.id = user_my_modules.my_module_id")
      .where('activities.id < ?', last_activity_id)
      .where(user_projects: { user_id: self })
      .where(
        'activities.my_module_id IS NULL OR ' +
        'user_projects.role = 0 OR ' +
        'user_my_modules.user_id = ?',
        id
      )
      .order(created_at: :desc)
      .limit(per_page)
      .uniq
  end

  def self.find_by_valid_wopi_token(token)
    Rails.logger.warn "Searching by token #{token}"
    user = User.where("wopi_token = ?", token).first
    return user
  end

  def token_valid
    if !self.wopi_token.nil? and (self.wopi_token_ttl==0 or self.wopi_token_ttl > Time.now.to_i)
      return true
    else
      return false
    end
  end

  def get_wopi_token
    unless token_valid
      # if current token is not valid generate a new one with a one day TTL
      self.wopi_token = Devise.friendly_token(20)
      # WOPI uses millisecond TTLs
      self.wopi_token_ttl = Time.now.to_i + 60*60*24
      self.save
      Rails.logger.warn("Generating new token #{self.wopi_token}")
    end
    Rails.logger.warn("Returning token #{self.wopi_token}")
    self.wopi_token
  end

protected

  def time_zone_check
    if time_zone.nil? or ActiveSupport::TimeZone.new(time_zone).nil?
      errors.add(:time_zone)
    end
  end


end

