# frozen_string_literal: true

class LabelTemplate < ApplicationRecord
  include SearchableModel
  include SearchableByNameModel

  belongs_to :team
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :last_modified_by, class_name: 'User', optional: true

  SEARCHABLE_ATTRIBUTES = ['label_templates.name',
                           'label_templates.description'].freeze

  enum :unit, { in: 0, mm: 1 }

  validates :name, presence: true, length: { minimum: Constants::NAME_MIN_LENGTH,
                                             maximum: Constants::NAME_MAX_LENGTH }
  validates :content, presence: true

  validate :ensure_single_default_template!

  scope :default, -> { where(default: true) }
  scope :predefined, -> { where(predefined: true) }

  def self.readable_by_user(user, teams)
    where(team: Team.with_granted_permissions(user, TeamPermissions::LABEL_TEMPLATES_READ, teams))
  end

  def self.enabled?
    ApplicationSettings.instance.values['label_templates_enabled'] == true
  end

  def self.search(
    user,
    _include_archived,
    query = nil,
    teams = user.teams,
    _options = {}
  )
    distinct.readable_by_user(user, teams)
            .where_attributes_like_boolean(SEARCHABLE_ATTRIBUTES, query)
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
