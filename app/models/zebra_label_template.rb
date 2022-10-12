# frozen_string_literal: true

class ZebraLabelTemplate < LabelTemplate
  def self.default
    template = ZebraLabelTemplate.new(
      name: I18n.t('label_templates.default_zebra_name'),
      width_mm: 25.4,
      height_mm: 12.7,
      content: Extends::DEFAULT_LABEL_TEMPLATE[:zpl]
    )

    if ZebraLabelTemplate.has_attribute?(:unit) && ZebraLabelTemplate.has_attribute?(:density)
      template.unit = 0
      template.density = 8
    end

    template
  end
end
