# frozen_string_literal: true

class ZebraLabelTemplate < LabelTemplate
  def self.default
    ZebraLabelTemplate.new(
      name: I18n.t('label_templates.default_zebra_name'),
      width_mm: 25.4,
      height_mm: 12.7,
      content: Extends::DEFAULT_LABEL_TEMPLATE[:zpl],
      unit: 0,
      density: 12,
      predefined: true
    )
  end

  def self.default_203dpi
    ZebraLabelTemplate.new(
      name: I18n.t('label_templates.default_zebra_name_203dpi'),
      width_mm: 25.4,
      height_mm: 12.7,
      content: Extends::DEFAULT_LABEL_TEMPLATE_203DPI[:zpl],
      unit: 0,
      density: 12,
      predefined: true
    )
  end
end
