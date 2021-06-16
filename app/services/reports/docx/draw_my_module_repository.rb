# frozen_string_literal: true

module Reports::Docx::DrawMyModuleRepository
  def draw_my_module_repository(subject, my_module = nil, snapshot = nil)
    my_module ||= subject&.my_module
    repository = subject&.repository
    repository = assigned_repository_or_snapshot(my_module, repository&.id, nil, snapshot)
    return unless can_read_experiment?(@user, my_module.experiment) &&
                  (can_read_repository?(@user, repository) || repository.is_a?(RepositorySnapshot))

    repository_data = my_module.repository_docx_json(repository)

    return false unless repository_data[:rows].any? && can_read_repository?(@user, repository)

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
