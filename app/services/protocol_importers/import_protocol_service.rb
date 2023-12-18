# frozen_string_literal: true

module ProtocolImporters
  class ImportProtocolService
    extend Service

    attr_reader :errors, :protocol

    def initialize(protocol_params:, steps_params_json:, team:, user:)
      @user = user
      @team = team
      @protocol_params = protocol_params
      @steps_params = JSON.parse(steps_params_json)
      @errors = {}
    end

    # rubocop:disable Metrics/BlockLength
    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @protocol = Protocol.create!(@protocol_params.merge!(added_by: @user, team: @team))

        TinyMceAsset.update_images(@protocol, '[]', @user)

        @steps_params.map do |step_params|
          step_params.symbolize_keys!

          # Create step with nested attributes for tables
          step = @protocol.steps.create!(step_params.slice(:name, :position)
                                  .merge(user: @user, completed: false)
                                  .merge(last_modified_by_id: @user.id))

          # Add description text block
          step_text = step.step_texts.create!(text: step_params[:description])
          step.step_orderable_elements.create!(
            position: 0,
            orderable: step_text
          )
          TinyMceAsset.update_images(step_text, '[]', @user)

          # Add tables
          if step_params[:tables_attributes].present?
            step_params[:tables_attributes].each do |table_attributes|
              table_attributes.symbolize_keys!
              table = step.tables.create!(
                name: table_attributes[:name],
                contents: JSON.parse(table_attributes[:contents].encode('UTF-8', 'UTF-8')).to_json,
                metadata: JSON.parse(table_attributes[:metadata].presence || '{}'),
                created_by: @user,
                last_modified_by: @user,
                team: @team
              )
              step.step_orderable_elements.create!(
                position: step.step_orderable_elements.size,
                orderable: table.step_table
              )
            end
          end

          # 'Manually' create assets here. "Accept nested attributes" won't work for assets
          step.assets << AttachmentsBuilder.generate(step_params.deep_symbolize_keys, user: @user, team: @team)
          step
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors[:protocol] = e.record.errors
        raise ActiveRecord::Rollback
      rescue StandardError => e
        Rails.logger.error(e.message)
        Rails.logger.error(e.backtrace.join("\n"))
        @errors[:protocol] = e.message
        raise ActiveRecord::Rollback
      end

      self
    end
    # rubocop:enable Metrics/BlockLength

    def succeed?
      @errors.none?
    end

    private

    def valid?
      unless [@protocol_params, @user, @team].all?
        @errors[:invalid_arguments] = {
          'user': @user,
          'team': @team,
          '@protocol_params': @protocol_params
        }.map { |key, value| "Can't find #{key.capitalize}" if value.nil? }.compact
        return false
      end
      true
    end
  end
end
