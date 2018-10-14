class Project < ApplicationRecord
  include ArchivableModel, SearchableModel

  enum visibility: { hidden: 0, visible: 1 }

  auto_strip_attributes :name, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :team, case_sensitive: false }
  validates :visibility, presence: true
  validates :team, presence: true

  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  belongs_to :archived_by,
             foreign_key: 'archived_by_id',
             class_name: 'User',
             optional: true
  belongs_to :restored_by,
             foreign_key: 'restored_by_id',
             class_name: 'User',
             optional: true
  belongs_to :team, inverse_of: :projects, optional: true
  has_many :user_projects, inverse_of: :project
  has_many :users, through: :user_projects
  has_many :experiments, inverse_of: :project
  has_many :active_experiments, -> { where(archived: false) },
           class_name: 'Experiment'
  has_many :project_comments, foreign_key: :associated_id, dependent: :destroy
  has_many :activities, inverse_of: :project
  has_many :tags, inverse_of: :project
  has_many :reports, inverse_of: :project, dependent: :destroy
  has_many :report_elements, inverse_of: :project, dependent: :destroy

  after_commit do
    Views::Datatables::DatatablesReport.refresh_materialized_view
  end

  def self.visible_from_user_by_name(user, team, name)
    if user.is_admin_of_team? team
      return where('projects.archived IS FALSE AND projects.name ILIKE ?',
                   "%#{name}%")
    end
    joins(:user_projects)
      .where('user_projects.user_id = ? OR projects.visibility = 1', user.id)
      .where('projects.archived IS FALSE AND projects.name ILIKE ?',
             "%#{name}%")
  end

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
    user_projects.find_by_user_id(user)&.role
  end

  def sorted_active_experiments(sort_by = :new)
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

  def notifications_count(user)
    res = 0
    assigned_modules(user).find_each do |t|
      res += 1 if t.is_overdue? || t.is_one_day_prior?
    end
    res
  end

  def generate_report_pdf(user, team)
    ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
    proxy = Warden::Proxy.new({}, Warden::Manager.new({}))
    renderer = ApplicationController.renderer.new(warden: proxy)

    report = Report.generate_whole_project_report(
      self, user, team
    )

    page_html_string = renderer.render 'reports/new.html.erb',
                                       locals: { export_all: true },
                                       assigns: { project: self,
                                                  report: report }
    parsed_page_html = Nokogiri::HTML(page_html_string)
    parsed_pdf_html = parsed_page_html.at_css('#report-content')
    report.destroy

    filename = "#{name}_Report.pdf"
    parsed_pdf = ApplicationController.render(
      pdf: filename,
      header: { right: '[page] of [topage]' },
      locals: { content: parsed_pdf_html.to_s },
      template: 'reports/report.pdf.erb',
      disable_javascript: true,
      disable_internal_links: false,
      current_user: user,
      current_team: team
    )
    # Dirty workaround to convert absolute links back to relative ones, since
    # WickedPdf does the opposite, based on the path where the file parsing is
    # done
    parsed_pdf.gsub('/URI (file:////tmp/', '/URI (')
  end
end
