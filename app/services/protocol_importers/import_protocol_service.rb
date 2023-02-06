# frozen_string_literal: true

module ProtocolImporters
  class ImportProtocolService
    extend Service

    attr_reader :errors, :protocol

    def initialize(protocol_params:, steps_params_json:, team_id:, user_id:)
      @user = User.find_by_id user_id
      @team = Team.find_by_id team_id
      @protocol_params = protocol_params
      @steps_params = JSON.parse(steps_params_json)
      @errors = {}
    end

    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @protocol = Protocol.create!(@protocol_params.merge!(added_by: @user, team: @team))

        TinyMceAsset.update_images(@protocol, '[]', @user)

        @steps_params.map do |step_params|
          step_params.symbolize_keys!

          # Create step with nested attributes for tables
          step = @protocol.steps.create!(step_params.slice(:name, :position, :tables_attributes)
                                  .merge(user: @user, completed: false)
                                  .merge(last_modified_by_id: @user.id))

          # Add description text block
          step_text = step.step_texts.create!(text: step_params[:description])
          step.step_orderable_elements.create!(
            position: 0,
            orderable: step_text
          )

          TinyMceAsset.update_images(step_text, '[]', @user)

          # 'Manually' create assets here. "Accept nasted attributes" won't work for assets
          step.assets << AttachmentsBuilder.generate(step_params.deep_symbolize_keys, user: @user, team: @team)
          step
        end
      rescue StandardError => e
        @errors[:protocol] = format_error(e)
      end

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def format_error(err)
      error_type, *error_message = err.message.split(': ')[1].split(' ')
      { error_type.downcase.to_sym => [error_message.join(' ')] }
    end

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
