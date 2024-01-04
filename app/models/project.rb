# frozen_string_literal: true

class Project < ApplicationRecord
  ID_PREFIX = 'PR'
  include PrefixedIdModel
  SEARCHABLE_ATTRIBUTES = ['projects.name', PREFIXED_ID_SQL].freeze

  include ArchivableModel
  include SearchableModel
  include SearchableByNameModel
  include ViewableModel
  include PermissionCheckableModel
  include Assignable

  enum visibility: { hidden: 0, visible: 1 }

  auto_strip_attributes :name, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :team_id, case_sensitive: false }
  validates :visibility, presence: true
  validates :team, presence: true
  validate :project_folder_team, if: -> { project_folder.present? }
  validate :selected_user_role_validation, if: :bulk_assignment?

  before_validation :remove_project_folder, on: :update, if: :archived_changed?

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
  belongs_to :default_public_user_role,
             foreign_key: 'default_public_user_role_id',
             class_name: 'UserRole',
             optional: true
  belongs_to :team, inverse_of: :projects, touch: true
  belongs_to :project_folder, inverse_of: :projects, optional: true, touch: true
  has_many :user_projects, inverse_of: :project
  has_many :users, through: :user_assignments
  has_many :experiments, inverse_of: :project
  has_many :active_experiments, -> { where(archived: false) },
           class_name: 'Experiment'
  has_many :project_comments, foreign_key: :associated_id, dependent: :destroy
  has_many :activities, inverse_of: :project
  has_many :tags, inverse_of: :project
  has_many :reports, inverse_of: :project, dependent: :destroy
  has_many :report_elements, inverse_of: :project, dependent: :destroy

  accepts_nested_attributes_for :user_assignments,
                                allow_destroy: true,
                                reject_if: :all_blank

  scope :visible_to, (lambda do |user, team|
                        # Team owners see all projects in the team
                        if team.permission_granted?(user, TeamPermissions::MANAGE)
                          where(team: team)
                        else
                          where(team: team)
                            .left_outer_joins(user_assignments: :user_role)
                            .where(user_assignments: { user: user })
                            .where('? = ANY(user_roles.permissions)', ProjectPermissions::READ)
                        end
                      end)

  scope :templates, -> { where(template: true) }

  after_create :auto_assign_project_members, if: :visible?
  before_update :sync_project_assignments, if: :visibility_changed?

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    current_team = nil,
    options = {}
  )

    new_query = Project.viewable_by_user(user, current_team || user.teams)
                       .where_attributes_like(SEARCHABLE_ATTRIBUTES, query, options)
    new_query = new_query.active unless include_archived

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query.limit(Constants::SEARCH_LIMIT).offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def self.viewable_by_user(user, teams)
    joins(user_assignments: :user_role)
      .where(team: teams)
      .with_granted_permissions(user, ProjectPermissions::READ)
      .distinct
  end

  def self.with_children_viewable_by_user(user)
    joins("
      LEFT OUTER JOIN experiments ON experiments.project_id = projects.id
      LEFT OUTER JOIN user_assignments experiment_user_assignments
        ON experiment_user_assignments.assignable_id = experiments.id
        AND experiment_user_assignments.assignable_type = 'Experiment'
        AND experiment_user_assignments.user_id = #{user.id}
      LEFT OUTER JOIN user_roles experiment_user_roles
        ON experiment_user_roles.id = experiment_user_assignments.user_role_id
        AND experiment_user_roles.permissions @> ARRAY['#{ExperimentPermissions::READ}']::varchar[]
      LEFT OUTER JOIN my_modules ON my_modules.experiment_id = experiments.id
      LEFT OUTER JOIN user_assignments my_module_user_assignments
        ON my_module_user_assignments.assignable_id = my_modules.id
        AND my_module_user_assignments.assignable_type = 'MyModule'
        AND my_module_user_assignments.user_id = #{user.id}
      LEFT OUTER JOIN user_roles my_module_user_roles
        ON my_module_user_roles.id = my_module_user_assignments.user_role_id
        AND my_module_user_roles.permissions @> ARRAY['#{MyModulePermissions::READ}']::varchar[]
    ")
  end

  def self.filter_by_teams(teams = [])
    teams.blank? ? self : where(team: teams)
  end

  def permission_parent
    nil
  end

  def default_view_state
    {
      experiments: {
        active: { sort: 'new' },
        archived: { sort: 'new' },
        view_type: 'table'
      }
    }
  end

  def validate_view_state(view_state)
    if %w(cards table).exclude?(view_state.state.dig('experiments', 'view_type')) ||
       %w(new old atoz ztoa id_asc id_desc).exclude?(view_state.state.dig('experiments', 'active', 'sort')) ||
       %w(new old atoz ztoa id_asc id_desc archived_new archived_old).exclude?(view_state.state.dig('experiments', 'archived', 'sort'))
      view_state.errors.add(:state, :wrong_state)
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
    ProjectComment.from(comments, :comments).order(created_at: :asc)
  end

  def user_role(user)
    user_assignments.includes(:user_role).references(:user_role).find_by(user: user)&.user_role&.name
  end

  def sorted_experiments(user, sort_by = :new, archived = false)
    sort = case sort_by
           when 'old' then { created_at: :asc }
           when 'atoz' then { name: :asc }
           when 'ztoa' then { name: :desc }
           when 'id_asc' then { id: :asc }
           when 'id_desc' then { id: :desc }
           when 'archived_new' then { archived_on: :desc }
           when 'archived_old' then { archived_on: :asc }
           else { created_at: :desc }
           end
    experiments.readable_by_user(user).is_archived(archived).order(sort)
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

  def assigned_repositories_and_snapshots
    live_repositories = Repository.assigned_to_project(self)
    snapshots = RepositorySnapshot.assigned_to_project(self)
    (live_repositories + snapshots).sort_by { |r| r.name.downcase }
  end

  def my_modules_ids
    ids = active_experiments.map do |exp|
      exp.my_modules.pluck(:id) if exp.my_modules
    end
    ids.delete_if { |i| i.flatten.blank? }
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
      res += 1 if (t.is_overdue? || t.is_one_day_prior?) && !t.completed?
    end
    res
  end

  def comments
    project_comments
  end

  def generate_teams_export_report_html(
    user, team, html_title, obj_filenames = nil
  )
    ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
    proxy = Warden::Proxy.new({}, Warden::Manager.new({}))
    proxy.set_user(user, scope: :user, store: false)
    ApplicationController.renderer.defaults[:http_host] = Rails.application.routes.default_url_options[:host]
    renderer = ApplicationController.renderer.new(warden: proxy)

    report = Report.generate_whole_project_report(self, user, team)

    page_html_string =
      renderer.render 'reports/export',
                      locals: { report: report, export_all: true },
                      assigns: { settings: report.settings, obj_filenames: obj_filenames }
    parsed_page_html = Nokogiri::HTML(page_html_string)
    parsed_html = parsed_page_html.at_css('#report-content')

    # Style tables (mimick frontend processing)

    tables = parsed_html.css('.hot-table-contents')
                        .zip(parsed_html.css('.hot-table-container'), parsed_html.css('.hot-table-metadata'))
    tables.each do |table_input, table_container, metadata|
      is_plate_template = JSON.parse(metadata['value'])['plateTemplate'] if metadata && metadata['value'].present?
      table_vals = JSON.parse(table_input['value'])
      table_data = table_vals['data']
      table_headers = table_vals['headers']
      table_headers ||= Array.new(table_data[0].count) do |index|
        is_plate_template ? index + 1 : convert_index_to_letter(index)
      end

      table_el = table_container.add_child('<table class="handsontable"></table>').first

      # Add header row
      header_cell = '<th><div class="relative"><span>%s</span></div></th>'

      header_el = table_el.add_child('<thead></thead>').first
      row_el = header_el.add_child('<tr></tr>').first
      row_el.add_child(format(header_cell, '')).first
      table_headers.each do |col|
        row_el.add_child(format(header_cell, col)).first
      end

      # Add body rows
      body_cell = '<td>%s</td>'
      body_el = table_el.add_child('<tbody></tbody>').first
      table_data.each.with_index(1) do |row, idx|
        row_name = is_plate_template ? convert_index_to_letter(idx - 1) : idx
        row_el = body_el.add_child('<tr></tr>').first
        row_el.add_child(format(header_cell, row_name)).first
        row.each do |col|
          row_el.add_child(format(body_cell, col)).first
        end
      end
    end

    ApplicationController.render(
      layout: false,
      locals: {
        title: html_title,
        content: parsed_html.children.map(&:to_s).join
      },
      template: 'team_zip_exports/report',
      current_user: user,
      current_team: team
    )
  ensure
    report.destroy if report.present?
  end

  private

  def project_folder_team
    return if project_folder.team_id == team_id

    errors.add(:project_folder, I18n.t('activerecord.errors.models.project.attributes.project_folder.team'))
  end

  def remove_project_folder
    self.project_folder = nil
  end

  def auto_assign_project_members
    return if skip_user_assignments

    UserAssignments::ProjectGroupAssignmentJob.perform_now(
      team,
      self,
      last_modified_by&.id || created_by&.id
    )
  end

  def bulk_assignment?
    visible? && default_public_user_role.present?
  end

  def selected_user_role_validation
    errors.add(:default_public_user_role_id, :inclusion) unless default_public_user_role.in?(UserRole.all)
  end

  def sync_project_assignments
    if visible?
      auto_assign_project_members
    else
      UserAssignments::ProjectGroupUnAssignmentJob.perform_now(self)
    end
  end

  def convert_index_to_letter(index)
    ord_a = 'A'.ord
    ord_z = 'Z'.ord
    len = (ord_z - ord_a) + 1
    num = index

    col_name = ''
    while num >= 0
      col_name = ((num % len) + ord_a).chr + col_name
      num = (num / len).floor - 1
    end
    col_name
  end
end
