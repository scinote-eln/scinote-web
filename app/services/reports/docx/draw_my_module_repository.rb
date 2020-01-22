# frozen_string_literal: true

module Reports::Docx::DrawMyModuleRepository
  def draw_my_module_repository(subject)
    my_module = MyModule.find_by(id: subject['id']['my_module_id'])
    return unless my_module

    repository_id = subject['id']['repository_id']
    repository_data = my_module.repository_docx_json(repository_id)
    return false unless repository_data[:rows].any?

    repository = ::Repository.find(repository_id)
    table = prepare_row_columns(repository_data)

    @docx.p
    @docx.p I18n.t('projects.reports.elements.module_repository.name',
                   repository: repository.name,
                   my_module: my_module.name), bold: true, size: Constants::REPORT_DOCX_STEP_ELEMENTS_TITLE_SIZE
    @docx.table table, border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE

    @docx.p
    @docx.p
  end
end
