# frozen_string_literal: true

class TeamZipExport < ZipExport
  def self.exports_limit
    (ENV.fetch('EXPORT_ALL_LIMIT_24_HOURS') || 3).to_i
  end
end
