# frozen_string_literal: true

module ProtocolImporters
  class DocxService
    def initialize(files, user)
      @files = files
      @user = user
    end

    def import!
      # TODO: Implement actual logic
      ActiveRecord::Base.transaction do
        @protocol = @user.current_team
                         .protocols
                         .create!(
                           name: "PARSED PROTOCOL #{rand * 10000}",
                           protocol_type: :in_repository_draft,
                           added_by: @user
                         )
        create_notification!
      end
    end

    def create_notification!
      # TODO: Add proper protocol original file link
      protocol_download_link = "<a data-id='#{@protocol.id}' " \
                               "data-turbolinks='false' " \
                               "href='#'>" \
                               "#{@protocol.name}</a>"

      notification = Notification.create(
        type_of: :deliver,
        title: I18n.t('protocols.import_export.import_protocol_notification.title', link: protocol_download_link),
        message:  "#{I18n.t('protocols.import_export.import_protocol_notification.message')} " \
                  "<a data-id='#{@protocol.id}'  data-turbolinks='false' " \
                  "href='#{Rails.application.routes.url_helpers.protocol_path(@protocol)}'>" \
                  "#{@protocol.name}</a>"
      )

      UserNotification.create(notification: notification, user: @user)
    end
  end
end
