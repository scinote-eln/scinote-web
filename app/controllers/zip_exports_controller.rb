class ZipExportsController < ApplicationController
  before_action :load_var
  before_action :check_edit_permissions

  def download
    send_data @zip_export.zip_file,
              filename: @zip_export.file_file_name + '.zip',
              type: @zip_export.file_content_type
  end

  private

  def load_var
    @zip_export = ZipExport.find_by_id(params[:id])
    render_404 unless @zip_export
  end

  def check_edit_permissions
    render_403 unless @zip_export.user == current_user
  end
end
