# frozen_string_literal: true

class FluicsLabelTemplate < LabelTemplate
  def self.default
    FluicsLabelTemplate.new(
      name: I18n.t('label_templates.default_fluics_name'),
      width_mm: 25.4,
      height_mm: 12.7,
      content: Extends::DEFAULT_LABEL_TEMPLATE[:zpl],
      unit: 0,
      density: 12
    )
  end

  def label_format
    'Fluics'
  end

  def created_by_user
    'Fluics GmbH'
  end

  def modified_by
    'Fluics GmbH'
  end

  def icon
    'fluics'
  end

  def read_only?
    true
  end
end
