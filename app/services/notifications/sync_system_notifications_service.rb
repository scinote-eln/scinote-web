# frozen_string_literal: true

module Notifications
  class SyncSystemNotificationsService
    extend Service
    include HTTParty
    base_uri Rails.application.secrets.system_notifications_uri

    attr_reader :errors

    def initialize
      @errors = {}
    end

    def call
      call_api

      save_new_notifications if succeed?

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def call_api
      last_sync = SystemNotification.last_sync_timestamp
      channel = Rails.application.secrets.system_notifications_channel

      unless last_sync
        @errors[:last_sync_timestamp] = 'Cannot find last_sync_timestamp'
        return false
      end

      query = { query: { last_sync_timestamp: last_sync,
                         notifications_channel: channel },
                headers: { 'accept':
                            'application/vnd.system-notifications.1+json' } }

      # rubocop:disable Lint/ShadowedException:
      begin
        @api_call = self.class.get('/api/system_notifications', query)

        if @api_call.response.code.to_i != 200
          @errors[:api_error] =
            [@api_call.response.code.to_s, @api_call.response.message].join('-')
        end
      rescue SocketError, HTTParty::Error, StandardError => e
        @errors[e.class.to_s.downcase.to_sym] = e.message
      end
      # rubocop:enable Lint/ShadowedException:
    end

    def save_new_notifications
      @api_call.parsed_response['system_notifications'].each do |sn|
        # Save new notification if not exists or override old 1
        attrs =
          sn.slice('title',
                   'description',
                   'modal_title',
                   'modal_body',
                   'show_on_login',
                   'source_id')
            .merge('source_created_at':
                     Time.parse(sn['source_created_at']),
                   'last_time_changed_at':
                     Time.parse(sn['last_time_changed_at']))
            .symbolize_keys

        n = SystemNotification
            .where(source_id: attrs[:source_id]).first_or_initialize(attrs)

        if n.new_record?
          n.save!
        elsif n.last_time_changed_at < attrs[:last_time_changed_at]
          n.update_attributes!(attrs)
        end
      end
    end
  end
end
