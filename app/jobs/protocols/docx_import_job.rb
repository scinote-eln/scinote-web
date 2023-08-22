# frozen_string_literal: true

module Protocols
  class DocxImportJob < ApplicationJob
    include RenamingUtil

    class RequestFailureException < StandardError; end

    def perform(temp_files_ids, user_id, team_id)
      @user = User.find(user_id)
      @team = @user.teams.find(team_id)
      TempFile.where(id: temp_files_ids).each do |temp_file|
        temp_file.file.open do |protocol_file|
          parse_protocol(protocol_file)
        end
      end
    end

    private

    def parse_protocol(protocol_file)
      parser_url = ENV.fetch('PROTOCOLS_PARSER_URL', nil)
      raise RequestFailureException, 'Protocols parser URL is missing!' unless parser_url

      response = HTTParty.post(
        ENV.fetch('PROTOCOLS_PARSER_URL', nil),
        body: {
          file: File.open(protocol_file.open)
        }
      )

      unless response.success?
        create_failed_notification!
        raise RequestFailureException, "#{response.code}: #{response.message}"
      end

      ActiveRecord::Base.transaction do
        @protocol = @team.protocols.new(
          name: response['name'],
          description: response['description'],
          authors: response['authors'],
          protocol_type: :in_repository_draft,
          added_by: @user
        )

        # Try to rename record if needed
        rename_record(@protocol, :name) if @protocol.invalid?

        @protocol.save!
        create_steps!(response['steps']) if response['steps'].present?
        create_notification!
      rescue ActiveRecord::RecordInvalid => e
        create_failed_notification!
        Rails.logger.error(e.message)
      end
    end

    def create_steps!(steps_json)
      steps_json.each do |step_json|
        step = @protocol.steps.create!(
          name: step_json['name'].presence || 'New step',
          position: @protocol.steps.length,
          completed: false,
          user: @user,
          last_modified_by: @user
        )
        step_json['stepElements'].each do |step_element_json|
          step_element_json = step_element_json[1] if step_element_json.is_a? Array

          case step_element_json['type']
          when 'StepText'
            create_step_text_element!(step, step_element_json)
          when 'StepTable'
            create_step_table_element!(step, step_element_json)
          when 'StepList'
            create_step_list_element!(step, step_element_json)
          when 'StepFile'
            create_step_asset_element!(step, step_element_json)
          end
        end
      end
    end

    def create_step_text_element!(step, step_element_json)
      step_text = step.step_texts.create!(text: step_element_json['contents'])
      create_step_orderable_element!(step, step_text)
    end

    def create_step_table_element!(step, step_element_json)
      table = Table.create!(
        name: step_element_json['name'].presence || 'New table',
        contents: step_element_json['contents'],
        created_by: @user,
        last_modified_by: @user,
        team: @team
      )
      step_table = StepTable.create!(step: step, table: table)
      create_step_orderable_element!(step, step_table)
    end

    def create_step_list_element!(step, step_element_json)
      checklist = Checklist.create!(
        name: step_element_json['name'].presence || 'New list',
        step: step,
        created_by: @user,
        last_modified_by: @user
      )

      step_element_json['contents'].each do |item|
        checklist.checklist_items.create!(
          text: item.truncate(Constants::TEXT_MAX_LENGTH),
          checked: false,
          position: checklist.checklist_items.length,
          created_by: @user,
          last_modified_by: @user
        )
      end
      create_step_orderable_element!(step, checklist)
    end

    def create_step_asset_element!(step, step_element_json)
      asset = @team.assets.new(created_by: @user, last_modified_by: @user)
      # Decode the file bytes
      asset.file.attach(io: StringIO.new(Base64.decode64(step_element_json['contents'])), filename: 'file.blob')
      asset.save!
      step.step_assets.create!(asset: asset)
      asset.post_process_file(@protocol.team)
    end

    def create_step_orderable_element!(step, orderable)
      step.step_orderable_elements.create!(
        position: step.step_orderable_elements.length,
        orderable: orderable
      )
    end

    def create_notification!
      # TODO: Add proper protocol original file link
      protocol_download_link = "<a data-id='#{@protocol.id}' " \
                               "data-turbolinks='false' " \
                               "href='#'>" \
                               "#{@protocol.name}</a>"

      notification = Notification.create!(
        type_of: :deliver,
        title: I18n.t('protocols.import_export.import_protocol_notification.title', link: protocol_download_link),
        message:  "#{I18n.t('protocols.import_export.import_protocol_notification.message')} " \
                  "<a data-id='#{@protocol.id}'  data-turbolinks='false' " \
                  "href='#{Rails.application.routes.url_helpers.protocol_path(@protocol)}'>" \
                  "#{@protocol.name}</a>"
      )

      UserNotification.create!(notification: notification, user: @user)
    end

    def create_failed_notification!
      notification = Notification.create!(
        type_of: :deliver_error,
        title: I18n.t('protocols.import_export.import_protocol_notification_error.title')
      )

      UserNotification.create!(notification: notification, user: @user)
    end
  end
end
