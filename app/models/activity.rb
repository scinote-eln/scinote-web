# frozen_string_literal: true

class Activity < ApplicationRecord
  ASSIGNMENT_TYPES = %w(
    assign_user_to_project
    change_user_role_on_project
    unassign_user_from_project
    designate_user_to_my_module
    undesignate_user_from_my_module
    invite_user_to_team
    remove_user_from_team
    change_users_role_on_team
    change_user_role_on_experiment
    change_user_role_on_my_module
  ).freeze

  # invert the children hash to get a hash defining parents
  ACTIVITY_SUBJECT_PARENTS = Extends::ACTIVITY_SUBJECT_CHILDREN.invert.map do |k, v|
    k&.map { |s| [s.to_s.classify, v.to_s.classify.constantize.reflect_on_association(s)&.inverse_of&.name || v] }
  end.compact.sum.to_h.freeze

  include ActivityValuesModel
  include GenerateNotificationModel

  enum type_of: Extends::ACTIVITY_TYPES

  belongs_to :owner, inverse_of: :activities, class_name: 'User'
  belongs_to :subject, polymorphic: true, optional: true

  # For permissions check
  belongs_to :project, inverse_of: :activities, optional: true
  belongs_to :team, inverse_of: :activities

  # Associations for old activity type
  belongs_to :experiment, inverse_of: :activities, optional: true
  belongs_to :my_module, inverse_of: :activities, optional: true

  validate :activity_version
  validates :type_of, :owner, presence: true
  validates :subject_type, inclusion: { in: Extends::ACTIVITY_SUBJECT_TYPES,
                                        allow_blank: true }

  scope :results_joins, lambda {
    joins("LEFT JOIN results ON subject_type = 'Result' AND subject_id = results.id")
  }

  scope :protocols_joins, lambda {
    joins("LEFT JOIN protocols ON subject_type = 'Protocol' AND subject_id = protocols.id")
  }

  scope :my_modules_joins, lambda { |*params|
    joins_query = "LEFT JOIN my_modules ON (subject_type = 'MyModule' AND subject_id = my_modules.id)"
    joins_query += ' OR protocols.my_module_id = my_modules.id' if params.include? :from_protocols
    joins_query += ' OR results.my_module_id = my_modules.id' if params.include? :from_results
    joins(joins_query)
  }
  scope :experiments_joins, lambda { |*params|
    joins_query = "LEFT JOIN experiments ON (subject_type = 'Experiment' AND subject_id = experiments.id)"
    joins_query += ' OR experiments.id = my_modules.experiment_id' if params.include? :from_my_modules
    joins(joins_query)
  }

  scope :projects_joins, lambda { |*params|
    joins_query = "LEFT JOIN projects ON (subject_type = 'Project' AND subject_id = projects.id)"
    joins_query += ' OR projects.id = experiments.project_id' if params.include? :from_experiments
    joins(joins_query)
  }

  scope :repositories_joins, lambda {
    joins("LEFT JOIN repositories ON subject_type = 'RepositoryBase' AND subject_id = repositories.id")
  }

  scope :reports_joins, lambda {
    joins("LEFT JOIN reports ON subject_type = 'Report' AND subject_id = reports.id")
  }

  store_accessor :values, :message_items, :breadcrumbs

  default_values(
    message_items: {},
    breadcrumbs: {}
  )

  after_create ->(activity) { Activities::DispatchWebhooksJob.perform_later(activity) },
               if: -> { Rails.application.config.x.webhooks_enabled }

  def self.activity_types_list
    activity_list = type_ofs.map do |key, value|
      [
        I18n.t("global_activities.activity_name.#{key}"),
        value
      ]
    end.sort_by { |a| a[0] }
    activity_groups = Extends::ACTIVITY_GROUPS

    result = {}

    activity_groups.each do |key, activities|
      group_name = I18n.t("global_activities.activity_group.#{key}")
      result[group_name] = []
      activities.each do |activity_id|
        activity_hash = activity_list.select { |activity| activity[1] == activity_id }[0]
        result[group_name].push(activity_hash) if activity_hash
      end
    end
    result
  end

  def old_activity?
    subject_id.nil?
  end

  def generate_breadcrumbs
    generate_breadcrumb subject if subject
  end

  def self.url_search_query(filters)
    result = []
    filters.each do |filter, values|
      result.push(values.transform_values { |v| v.collect(&:id) }.to_query(filter))
    end
    if filters[:subjects]
      subject_labels = []
      filters[:subjects].each do |object, values|
        values.each do |value|
          label = value.name
          subject_labels.push({ value: value.id, label: label, object: object.downcase, group: '' }.as_json)
        end
      end
      result.push(subject_labels.to_query('subject_labels'))
    end
    result.join('&')
  end

  def subject_parents
    recursive_subject_parents(subject, []).compact
  end

  def recursive_subject_parents(activity_subject, parents)
    parent_model_name = ACTIVITY_SUBJECT_PARENTS[activity_subject.class.name]
    return parents if parent_model_name.nil?

    parent = activity_subject.public_send(parent_model_name)
    recursive_subject_parents(parent, parents << parent)
  end

  private

  def generate_breadcrumb(subject)
    case subject
    when Protocol
      breadcrumbs[:protocol] = subject.name
      if subject.in_repository?
        generate_breadcrumb(subject.team)
      else
        generate_breadcrumb(subject.my_module)
      end
    when MyModule
      breadcrumbs[:my_module] = subject.name
      generate_breadcrumb(subject.experiment)
    when Experiment
      breadcrumbs[:experiment] = subject.name
      generate_breadcrumb(subject.project)
    when Project
      breadcrumbs[:project] = subject.name
      generate_breadcrumb(subject.team)
    when Repository
      breadcrumbs[:repository] = subject.name
      generate_breadcrumb(subject.team)
    when Result
      breadcrumbs[:result] = subject.name
      generate_breadcrumb(subject.my_module)
    when Team
      breadcrumbs[:team] = subject.name
    when LabelTemplate
      breadcrumbs[:label_template] = subject.name
      generate_breadcrumb(subject.team) if subject.team
    when Report
      breadcrumbs[:report] = subject.name
      generate_breadcrumb(subject.team) if subject.team
    when ProjectFolder
      breadcrumbs[:project_folder] = subject.name
      generate_breadcrumb(subject.team)
    when Step
      breadcrumbs[:step] = subject.name
      generate_breadcrumb(subject.protocol)
    when Asset
      breadcrumbs[:asset] = subject.blob.filename.to_s
      generate_breadcrumb(subject.result || subject.step || subject.repository_cell.repository_row.repository)
    end
  end

  def activity_version
    errors.add(:activity, 'wrong combination of associations') if (experiment_id || my_module_id) && subject
  end
end
