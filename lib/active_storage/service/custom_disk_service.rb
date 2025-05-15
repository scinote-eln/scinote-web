# frozen_string_literal: true

require 'active_storage/service/disk_service'

module ActiveStorage
  class Service::CustomDiskService < Service::DiskService
    def url_options
      ActiveStorage::Current.url_options ||= { host: ENV.fetch('MAIL_SERVER_URL', 'localhost') }
      ActiveStorage::Current.url_options
    end
  end
end
