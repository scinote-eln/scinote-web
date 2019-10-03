# frozen_string_literal: true

require 'active_storage/service/disk_service'

module ActiveStorage
  class Service::CustomDiskService < Service::DiskService
    def current_host
      host = ActiveStorage::Current.host
      host ||= Rails.application.secrets.mail_server_url
      host = "http://#{host}" unless host.match?(/^http/)
      host
    end
  end
end
