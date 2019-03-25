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
    type_ofs.map  do |key, value|
      {
        id: value,
        name: key.tr('_', ' ').capitalize
      }
    end.sort_by { |a| a[:name] }
  end

  def old_activity?
    subject_id.nil?
  end

  def generate_breadcrumbs
    generate_breadcrumb subject if subject
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
    end
    save!
  end

  def activity_version
    if (experiment || my_module) && subject
      errors.add(:activity, 'wrong combination of associations')
    end
  end
end
