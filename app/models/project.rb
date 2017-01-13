class Project < ActiveRecord::Base
  include ArchivableModel, SearchableModel

  enum visibility: { hidden: 0, visible: 1 }

  auto_strip_attributes :name, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :organization, case_sensitive: false }
  validates :visibility, presence: true
  validates :organization, presence: true

  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User'
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  belongs_to :archived_by, foreign_key: 'archived_by_id', class_name: 'User'
  belongs_to :restored_by, foreign_key: 'restored_by_id', class_name: 'User'
  has_many :user_projects, inverse_of: :project
  has_many :users, through: :user_projects
  has_many :experiments, inverse_of: :project
  has_many :project_comments, inverse_of: :project
  has_many :comments, through: :project_comments
  has_many :activities, inverse_of: :project
  has_many :tags, inverse_of: :project
  has_many :reports, inverse_of: :project, dependent: :destroy
  has_many :report_elements, inverse_of: :project, dependent: :destroy
  belongs_to :organization, inverse_of: :projects

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    current_organization = nil
  )

    if query
      a_query = '%' + query.strip.gsub("_","\\_").gsub("%","\\%") + '%'
    else
      a_query = query
    end

    if current_organization
      new_query = Project
                  .distinct
                  .joins(:user_projects)
                  .where('projects.organization_id = ?',
                         current_organization.id)
                  .where('projects.visibility = 1 OR user_projects.user_id = ?',
                         user.id)
                  .where_attributes_like(:name, a_query)
                  .limit(Constants::ATWHO_SEARCH_LIMIT)
      return new_query
    else
      org_ids =
        Organization
        .joins(:user_organizations)
        .where('user_organizations.user_id = ?', user.id)
        .select('id')
        .distinct

      if include_archived
        new_query = Project
                    .distinct
                    .joins(:user_projects)
                    .where('projects.organization_id IN (?)', org_ids)
                    .where(
                      'projects.visibility = 1 OR user_projects.user_id = ?',
                      user.id
                    )
                    .where_attributes_like(:name, a_query)

      else
        new_query = Project
                    .distinct
                    .joins(:user_projects)
                    .where('projects.organization_id IN (?)', org_ids)
                    .where(
                      'projects.visibility = 1 OR user_projects.user_id = ?',
                      user.id
                    )
                    .where_attributes_like(:name, a_query)
                    .where('projects.archived = ?', false)
      end
    end

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def last_activities(count = Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
    activities.order(created_at: :desc).first(count)
  end

  # Get project comments order by created_at time. Results are paginated
  # using last comment id and per_page parameters.
  def last_comments(last_id = 1, per_page = Constants::COMMENTS_SEARCH_LIMIT)
    last_id = Constants::INFINITY if last_id <= 1
    comments = Comment.joins(:project_comment)
                      .where(project_comments: { project_id: id })
                      .where('comments.id <  ?', last_id)
                      .order(created_at: :desc)
                      .limit(per_page)
    comments.reverse
  end

  def unassigned_users
    User
      .joins('INNER JOIN user_organizations ON users.id = user_organizations.user_id')
      .where('user_organizations.organization_id = ?', organization)
      .where.not(confirmed_at: nil)
      .where('users.id NOT IN (?)',
             UserProject.where(project: self).select(:user_id).distinct)
  end

  def user_role(user)
    unless self.users.include? user
      return nil
    end

    return (self.user_projects.select { |up| up.user == user }).first.role
  end

  def active_experiments(sort_by = :new)
    sort = case sort_by
           when 'old' then { created_at: :asc }
           when 'atoz' then { name: :asc }
           when 'ztoa' then { name: :desc }
           else { created_at: :desc }
           end
    experiments.is_archived(false).order(sort)
  end

  def archived_experiments
    experiments.is_archived(true)
  end

  def project_my_modules
    MyModule.where('"experiment_id" IN (?)', experiments.select(:id))
  end

  def space_taken
    st = 0
    project_my_modules.find_each do |my_module|
      st += my_module.space_taken
    end
    st
  end

  # Writes to user log.
  def log(message)
    final = "[%s] %s" % [name, message]
    organization.log(final)
  end

  def assigned_samples
    Sample.joins(:my_modules).where(my_modules: {
                                      id: my_modules_ids.split(',')
                                    })
  end

  def my_modules_ids
    ids = active_experiments.map do |exp|
      exp.my_modules.pluck(:id) if exp.my_modules
    end
    ids.delete_if { |i| i.flatten.empty? }
    ids.join(', ')
  end

  def assigned_modules(user)
    role = user_role(user)
    if role.blank?
      MyModule.none
    elsif role == 'owner'
      project_my_modules
        .joins(:experiment)
        .where('experiments.archived=false')
        .where('my_modules.archived=false')

    else
      project_my_modules
        .joins(:user_my_modules)
        .joins(:experiment)
        .where('experiments.archived=false AND user_my_modules.user_id IN (?)',
               user.id)
        .where('my_modules.archived=false')
        .distinct
    end
  end
end
