# frozen_string_literal: true

class LabelTemplate < ApplicationRecord
  include SearchableModel

  belongs_to :team
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :last_modified_by, class_name: 'User', optional: true

  SEARCHABLE_ATTRIBUTES = ['label_templates.name',
                           'label_templates.description'].freeze

  enum unit: { in: 0, mm: 1 }

  validates :name, presence: true, length: { minimum: Constants::NAME_MIN_LENGTH,
                                             maximum: Constants::NAME_MAX_LENGTH }
  validates :content, presence: true

  validate :ensure_single_default_template!

  scope :default, -> { where(default: true) }

  def self.enabled?
    ApplicationSettings.instance.values['label_templates_enabled'] == true
  end

  def self.search(
    _user,
    _include_archived,
    query = nil,
    page = 1,
    _current_team = nil,
    options = {}
  )

    new_query = LabelTemplate.where_attributes_like(SEARCHABLE_ATTRIBUTES, query, options)

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query.limit(Constants::SEARCH_LIMIT).offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def icon
    'zpl'
  end

  def language_type
    'zpl'
  end

  def read_only?
    false
  end

  def label_format
    Extends::LABEL_TEMPLATE_FORMAT_MAP[type]
  end

  private

  def ensure_single_default_template!
    if default && self.class.where(team_id: team_id, default: true, type: type)
                      .where.not(id: id).any?
      errors.add(:default, I18n.t('activerecord.errors.models.label_template.attributes.default.already_exist'))
    end
  end
end
