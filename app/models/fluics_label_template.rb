# frozen_string_literal: true

class FluicsLabelTemplate < LabelTemplate
  def self.default
    template = FluicsLabelTemplate.new(
      name: I18n.t('label_templates.default_fluics_name'),
      width_mm: 25.4,
      height_mm: 12.7,
      content: Extends::DEFAULT_LABEL_TEMPLATE[:zpl]
    )
    if FluicsLabelTemplate.has_attribute?(:unit) && FluicsLabelTemplate.has_attribute?(:density)
      template.unit = 0
      template.density = 8
    end

    template
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
