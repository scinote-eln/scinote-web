# frozen_string_literal: true

class Report < ApplicationRecord
  ID_PREFIX = 'RP'
  include PrefixedIdModel
  SEARCHABLE_ATTRIBUTES = ['reports.name', 'reports.description', PREFIXED_ID_SQL].freeze

  include SettingsModel
  include Assignable
  include PermissionCheckableModel
  include SearchableModel
  include SearchableByNameModel

  enum pdf_file_status: { pdf_empty: 0, pdf_processing: 1, pdf_ready: 2, pdf_error: 3 }
  enum docx_file_status: { docx_empty: 0, docx_processing: 1, docx_ready: 2, docx_error: 3 }

  # ActiveStorage configuration
  has_one_attached :pdf_file
  has_one_attached :docx_file
  has_one_attached :docx_preview_file

  auto_strip_attributes :name, :description, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :project, presence: true
  validates :user, presence: true

  belongs_to :project, inverse_of: :reports
  belongs_to :user, inverse_of: :reports
  belongs_to :team, inverse_of: :reports
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  has_many :users, through: :user_assignments
  has_many :report_template_values, dependent: :destroy

  # Report either has many report elements (if grouped by timestamp),
  # or many module elements (if grouped by module)
  has_many :report_elements, inverse_of: :report, dependent: :delete_all

  DEFAULT_SETTINGS = {
    all_tasks: true,
    exclude_task_metadata: false,
    exclude_timestamps: false,
    task: {
      protocol: {
        description: true,
        completed_steps: true,
        uncompleted_steps: true,
        step_texts: true,
        step_checklists: true,
        step_files: true,
        step_tables: true,
        step_comments: true,
        step_forms: true,
        step_well_plates: true
      },
      file_results: true,
      file_results_previews: false,
      table_results: true,
      text_results: true,
      result_comments: true,
      result_order: 'new',
      activities: true,
      repositories: [],
      excluded_repository_columns: {}
    },
    template: 'scinote_template',
    docx_template: 'scinote_template'
  }.freeze

  def self.search(
    user,
    _include_archived,
    query = nil,
    current_team = nil,
    options = {}
  ) 
    teams = options[:teams] || current_team || user.teams.select(:id)
    distinct.with_granted_permissions(user, ReportPermissions::READ)
            .where(team: teams)
            .where_attributes_like_boolean(SEARCHABLE_ATTRIBUTES, query, options)
  end

  def self.viewable_by_user(user, teams)
    with_granted_permissions(user, ReportPermissions::READ)
      .where(project: Project.viewable_by_user(user, teams))
  end

  def self.filter_by_teams(teams = [])
    teams.blank? ? self : where(team: teams)
  end

  def created_by
    user
  end

  def permission_parent
    team
  end

  def root_elements
    report_elements.active.where(parent: nil).order(:position)
  end

  def self.generate_whole_project_report(project, current_user, current_team)
    content = {
      'experiments' => [],
      'repositories' => project.assigned_readable_repositories_and_snapshots(current_user).pluck(:id)
    }
    project.experiments.includes(:my_modules).find_each do |experiment|
      content['experiments'].push(
        { id: experiment.id, my_module_ids: experiment.my_module_ids }
      )
    end

    report = Report.new(skip_user_assignments: true)
    report.name = loop do
      dummy_name = SecureRandom.hex(10)
      break dummy_name unless Report.exists?(name: dummy_name)
    end
    report.project = project
    report.user = current_user
    report.team = current_team
    report.last_modified_by = current_user
    report.settings[:task][:repositories] = content['repositories']
    ReportActions::ReportContent.new(report, content, {}, current_user).save_with_content
    report
  end

  def self.default_repository_columns
    {
      '-1': I18n.t('repositories.table.id'),
      '-2': I18n.t('repositories.table.row_name'),
      '-3': I18n.t('repositories.table.added_on'),
      '-4': I18n.t('repositories.table.added_by')
    }
  end
end
