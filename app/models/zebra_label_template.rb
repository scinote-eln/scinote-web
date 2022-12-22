# frozen_string_literal: true

class ZebraLabelTemplate < LabelTemplate
  def self.default
    ZebraLabelTemplate.new(
      name: I18n.t('label_templates.default_zebra_name'),
      width_mm: 25.4,
      height_mm: 12.7,
      content: Extends::DEFAULT_LABEL_TEMPLATE[:zpl],
      unit: 0,
      density: 12
    )
  end
end
