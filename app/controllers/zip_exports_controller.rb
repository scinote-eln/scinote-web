require 'zip'
require 'fileutils'

class ZipExportsController < ApplicationController
  before_action :load_var
  before_action :check_edit_permissions

  def download
    if @zip_export.stored_on_s3?
      redirect_to @zip_export.presigned_url(download: true), status: 307
    else
      send_file @zip_export.zip_file.path,
                filename: URI.unescape(@zip_export.zip_file_file_name),
                type: @zip_export.file_content_type
    end
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
