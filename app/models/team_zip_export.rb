# frozen_string_literal: true

class TeamZipExport < ZipExport
  def self.exports_limit
    Rails.configuration.x.export_all_limit_24h
  end
end
