# frozen_string_literal: true

class Activity < ApplicationRecord
  include ActivityValuesModel

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

  store_accessor :values, :message_items, :breadcrumbs

  default_values(
    message_items: {},
    breadcrumbs: {}
  )

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
      result.push(values.to_query(filter))
    end
    if filters[:subjects]
      subject_labels = []
      filters[:subjects].each do |object, values|
        values.each do |value|
          label = object.to_s.constantize.find_by_id(value).name
          subject_labels.push({ value: value, label: label, object: object.downcase, group: '' }.as_json)
        end
      end
      result.push(subject_labels.to_query('subject_labels'))
    end
    result.join('&')
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
    when Report
      breadcrumbs[:report] = subject.name
      generate_breadcrumb(subject.team) if subject.team
    end
  end

  def activity_version
    errors.add(:activity, 'wrong combination of associations') if (experiment_id || my_module_id) && subject
  end
end
