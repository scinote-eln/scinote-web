# frozen_string_literal: true

class RepositoryExportService
  def initialize(file_type, rows, columns, repository, user, handle_name_func = nil, in_module: false, ordered_row_ids: nil)
    @file_type = file_type
    @rows = rows
    @columns = columns
    @repository = repository
    @handle_name_func = handle_name_func
    @in_module = in_module
    @ordered_row_ids = ordered_row_ids
    @user = user
  end

  def export!
    case @file_type
    when :csv
      file_data = RepositoryCsvExport.to_csv(@rows, @columns, @repository, @handle_name_func, @in_module, @user, @ordered_row_ids)
    when :xlsx
      file_data = RepositoryXlsxExport.to_xlsx(@rows, @columns, @repository, @handle_name_func, @in_module, @user, @ordered_row_ids)
    end

    file_data
  end
end
