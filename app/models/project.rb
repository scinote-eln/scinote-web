class Project < ActiveRecord::Base
  include ArchivableModel, SearchableModel

  enum visibility: { hidden: 0, visible: 1 }

  auto_strip_attributes :name, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :team, case_sensitive: false,
                          message: I18n.t('projects.create.name_taken') }
  validates :visibility, presence: true
  validates :team, presence: true

  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User'
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  belongs_to :archived_by, foreign_key: 'archived_by_id', class_name: 'User'
  belongs_to :restored_by, foreign_key: 'restored_by_id', class_name: 'User'
  has_many :user_projects, inverse_of: :project
  has_many :users, through: :user_projects
  has_many :experiments, inverse_of: :project
  has_many :project_comments, foreign_key: :associated_id, dependent: :destroy
  has_many :activities, inverse_of: :project
  has_many :tags, inverse_of: :project
  has_many :reports, inverse_of: :project, dependent: :destroy
  has_many :report_elements, inverse_of: :project, dependent: :destroy
  belongs_to :team, inverse_of: :projects

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    current_team = nil,
    options = {}
  )

    if current_team
      new_query =
        Project
        .distinct
        .joins(:user_projects)
        .where('projects.team_id = ?', current_team.id)
      unless user.user_teams.find_by(team: current_team).try(:admin?)
        # Admins see all projects in the team
        new_query = new_query.where(
          'projects.visibility = 1 OR user_projects.user_id = ?',
          user.id
        )
      end
      new_query = new_query.where_attributes_like(:name, query, options)

      if include_archived
        return new_query
      else
        return new_query.where('projects.archived = ?', false)
      end
    else
      new_query = Project
                  .distinct
                  .joins(team: :user_teams)
                  .where('user_teams.user_id = ?', user.id)

      if include_archived
        new_query =
          new_query
          .joins(:user_projects)
          .where(
            'user_teams.role = 2 OR projects.visibility = 1 OR ' \
            'user_projects.user_id = ?',
            user.id
          )
          .where_attributes_like('projects.name', query, options)

      else
        new_query =
          new_query
          .joins(:user_projects)
          .where(
            'user_teams.role = 2 OR projects.visibility = 1 OR ' \
            'user_projects.user_id = ?',
            user.id
          )
          .where_attributes_like('projects.name', query, options)
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
    comments = ProjectComment.joins(:project)
                             .where(projects: { id: id })
                             .where('comments.id <  ?', last_id)
                             .order(created_at: :desc)
                             .limit(per_page)
    comments.reverse
  end

  def unassigned_users
    User
      .joins('INNER JOIN user_teams ON users.id = user_teams.user_id')
      .where('user_teams.team_id = ?', team)
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
