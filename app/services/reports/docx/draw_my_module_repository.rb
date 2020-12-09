# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawMyModuleRepository
<<<<<<< HEAD
  def draw_my_module_repository(subject)
    my_module = subject.my_module
    repository = subject.repository
    repository = assigned_repository_or_snapshot(my_module, repository)

    return unless repository && can_read_experiment?(@user, my_module.experiment) &&
                  (repository.is_a?(RepositorySnapshot) || can_read_repository?(@user, repository))

    repository_data = my_module.repository_docx_json(repository)

    return false unless repository_data[:rows].any? && can_read_repository?(@user, repository)

    table = prepare_row_columns(repository_data)
=======
module DrawMyModuleRepository
=======
module Reports::Docx::DrawMyModuleRepository
>>>>>>> Initial commit of 1.17.2 merge
  def draw_my_module_repository(subject)
    my_module = MyModule.find_by_id(subject['id']['my_module_id'])
=======
  def draw_my_module_repository(subject, my_module)
>>>>>>> Pulled latest release
    return unless my_module

    repository_id = subject['id']['repository_id']
    repository = ::RepositoryBase.find(repository_id)
    repository_data = my_module.repository_docx_json(repository)

    return false unless repository_data[:rows].any? && can_read_repository?(@user, repository)

<<<<<<< HEAD
    data.map! do |row|
      row.select do |key, _value|
        true if Float(key.to_s) > 1
      rescue StandardError
        false
      end
    end

    table = []
    data.each do |row|
      new_row = Array.new(repository_data[:headers].length)
      row.each do |key, value|
        new_row[(key.to_s.to_i - 2)] = Sanitize.clean(value)
      end
      table.push(new_row)
    end
    table.unshift(repository_data[:headers])
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    table = prepare_row_columns(repository_data)
>>>>>>> Pulled latest release

    @docx.p
    @docx.p I18n.t('projects.reports.elements.module_repository.name',
                   repository: repository.name,
                   my_module: my_module.name), bold: true, size: Constants::REPORT_DOCX_STEP_ELEMENTS_TITLE_SIZE
    @docx.table table, border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE

    @docx.p
    @docx.p
  end
end
