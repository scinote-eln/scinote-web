# frozen_string_literal: true

class ZipExportsController < ApplicationController
  before_action :load_var, only: %i(download download_export_all_zip)
  before_action :check_download_permissions, except: :file_expired

  def download
    if !@zip_export.zip_file.attached?
      render_404
    else
      redirect_to rails_blob_path(@zip_export.zip_file, disposition: 'attachment')
    end
  end

  def download_export_all_zip
    download
  end

  def file_expired; end

  private

  def load_var
    @zip_export = current_user.zip_exports.find_by_id(params[:id])
    redirect_to(file_expired_url, status: 301) and return unless @zip_export&.zip_file&.exists?
  end

  def check_download_permissions
    render_403 unless @zip_export.user == current_user
  end
end
