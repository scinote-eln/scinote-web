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

  store_accessor :values, :message_items

  default_values(
    message_items: {}
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
    subject.nil?
  end

  private

  def activity_version
    if (experiment || my_module) && subject
      errors.add(:activity, 'wrong combination of associations')
    end
  end
end
