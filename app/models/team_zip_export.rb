# frozen_string_literal: true

class TeamZipExport < ZipExport
  def self.exports_limit
    (Rails.application.secrets.export_all_limit_24h || 3).to_i
  end
end
