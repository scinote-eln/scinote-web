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

    def self.available?
      channel = Rails.application.secrets.system_notifications_channel
      query = { query: { last_sync_timestamp: Time.now.to_i, channels_slug: channel },
                headers: { 'accept': 'application/vnd.system-notifications.1+json' } }
      response = get('/api/system_notifications', query)
      response.code < Rack::Utils::SYMBOL_TO_STATUS_CODE[:bad_request]
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
                         channels_slug: channel },
                headers: { 'accept':
                            'application/vnd.system-notifications.1+json' } }

      # rubocop:disable Lint/ShadowedException:
      begin
        @api_call = self.class.get('/api/system_notifications', query)

        if @api_call.response.code.to_i != 200
          @errors[:api_error] =
            [@api_call.response.code.to_s, @api_call.response.message].join('-')

          # Add message for logging if exists
          if @api_call.parsed_response.try('error')
            @errors[:api_error] += ': ' + @api_call
                                   .parsed_response['error']
                                   .flatten&.join(' - ').to_s
          end
        end
      rescue SocketError, HTTParty::Error, StandardError => e
        @errors[e.class.to_s.downcase.to_sym] = e.message
      end
      # rubocop:enable Lint/ShadowedException:
    end

    def save_new_notifications
      @api_call.parsed_response['notifications'].each do |sn|
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
          save_notification n
        elsif n.last_time_changed_at < attrs[:last_time_changed_at]
          n.update!(attrs)
        end
      end
    end

    def save_notification(notification)
      ActiveRecord::Base.transaction do
        notification.save!

        User.find_in_batches do |user_ids|
          user_system_notifications = user_ids.pluck(:id).collect do |item|
            Hash[:user_id, item, :system_notification_id, notification.id]
          end
          UserSystemNotification.import user_system_notifications, validate: false
        end
      end

      Notifications::PushToCommunicationChannelService.delay.call(item_id: notification.id,
                                                            item_type: notification.class.name)
    end
  end
end
