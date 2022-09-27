# frozen_string_literal: true

class Report < ApplicationRecord
  include SettingsModel
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
  has_many :report_template_values, dependent: :destroy

  # Report either has many report elements (if grouped by timestamp),
  # or many module elements (if grouped by module)
  has_many :report_elements, inverse_of: :report, dependent: :delete_all

  DEFAULT_SETTINGS = {
    all_tasks: true,
    task: {
      protocol: {
        description: true,
        completed_steps: true,
        uncompleted_steps: true,
        step_texts: true,
        step_checklists: true,
        step_files: true,
        step_tables: true,
        step_comments: true
      },
      file_results: true,
      file_results_previews: false,
      table_results: true,
      text_results: true,
      result_comments: true,
      result_order: 'atoz',
      activities: true
    }
  }.freeze

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    _current_team = nil,
    options = {}
  )

    project_ids = Project.search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
                         .pluck(:id)

    new_query = Report.distinct
                      .where(reports: { project_id: project_ids })
                      .where_attributes_like(%i(name description), query, options)

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query.limit(Constants::SEARCH_LIMIT).offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def self.viewable_by_user(user, teams)
    where(project: Project.viewable_by_user(user, teams))
  end

  def self.filter_by_teams(teams = [])
    teams.blank? ? self : where(team: teams)
  end

  def root_elements
    report_elements.active.where(parent: nil).order(:position)
  end

  def self.generate_whole_project_report(project, current_user, current_team)
    content = {
      'experiments' => [],
      'repositories' => project.assigned_repositories_and_snapshots.pluck(:id)
    }
    project.experiments.includes(:my_modules).each do |experiment|
      content['experiments'].push(
        { id: experiment.id, my_module_ids: experiment.my_module_ids }
      )
    end

    report = Report.new
    report.name = loop do
      dummy_name = SecureRandom.hex(10)
      break dummy_name unless Report.exists?(name: dummy_name)
    end
    report.project = project
    report.user = current_user
    report.team = current_team
    report.last_modified_by = current_user
    ReportActions::ReportContent.new(report, content, {}, current_user).save_with_content
    report
  end
end
