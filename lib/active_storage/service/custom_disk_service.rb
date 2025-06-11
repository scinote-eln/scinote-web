# frozen_string_literal: true

require 'active_storage/service/disk_service'

module ActiveStorage
  class Service::CustomDiskService < Service::DiskService
    def url_options
      ActiveStorage::Current.url_options ||= { host: Rails.application.routes.default_url_options[:host] }
      ActiveStorage::Current.url_options
    end
  end
end
