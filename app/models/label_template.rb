# frozen_string_literal: true

class LabelTemplate < ApplicationRecord
  include SearchableModel

  enum language_type: { zpl: 0 }
  validates :name, presence: true, length: { minimum: Constants::NAME_MIN_LENGTH,
                                             maximum: Constants::NAME_MAX_LENGTH }
  validates :size, presence: true
  validates :content, presence: true

  validate :default_template

  def self.enabled?
    ApplicationSettings.instance.values['label_templates_enabled']
  end

  def render(locals)
    locals.reduce(content.dup) do |rendered_content, (key, value)|
      rendered_content.gsub!(/\{\{#{key}\}\}/, value.to_s)
    end
  end

  private

  def default_template
    if default && LabelTemplate.where(team_id: team_id, default: true, language_type: language_type)
                               .where.not(id: id).any?
      errors.add(:default, I18n.t('activerecord.errors.models.label_template.attributes.default.already_exist'))
    end
  end
end
