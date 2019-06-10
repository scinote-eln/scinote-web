# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::MyModuleSamples
  def draw_my_module_samples(my_module, repository, order)
    samples_json = my_module.repository_json_hot(repository, order)
    @docx.p
    @docx.p I18n.t 'projects.reports.elements.module_samples.name', my_module: my_module.name
    if samples_json[:data].count.positive?
      @docx.table JSON.parse(samples_json.to_json.force_encoding(Encoding::UTF_8))['data'], border_color: '666666'
    else
      I18n.t 'projects.reports.elements.module_samples.no_samples'
    end
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
