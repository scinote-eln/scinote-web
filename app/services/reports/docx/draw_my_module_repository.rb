# frozen_string_literal: true

module DrawMyModuleRepository
  def draw_my_module_repository(subject)
    my_module = MyModule.find_by_id(subject['id']['my_module_id'])
    return unless my_module

    repository_data = my_module.repository_json(subject['id']['repository_id'], subject['sort_order'], @user)
    return false unless repository_data[:data].assigned_rows.count.positive?

    records = repository_data[:data]
    assigned_rows = records.assigned_rows
    columns_mappings = records.mappings
    repository = ::Repository.find_by_id(subject['id']['repository_id'])
    repository_rows = records.repository_rows
                             .preload(
                               :repository_columns,
                               :created_by,
                               repository_cells: :value
                             )
    data = prepare_row_columns(repository_rows,
                               repository,
                               columns_mappings,
                               repository.team,
                               assigned_rows)

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

    @docx.p
    @docx.p I18n.t('projects.reports.elements.module_repository.name',
                   repository: repository.name,
                   my_module: my_module.name), bold: true
    @docx.table table, border_size: 4
    @docx.p
    @docx.p
  end
end
