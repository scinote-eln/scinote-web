# frozen_string_literal: true

require 'active_storage/service/disk_service'

module ActiveStorage
  class Service::CustomDiskService < Service::DiskService
    def url_options
      ActiveStorage::Current.url_options ||= { host: Rails.application.secrets.mail_server_url }
      ActiveStorage::Current.url_options
    end
  end
end
