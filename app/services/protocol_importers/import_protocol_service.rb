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

      @protocol = Protocol.new(@protocol_params.merge!(added_by: @user, team: @team))

      @protocol.steps << @steps_params.map do |step_params|
        # Create step with nested attributes for tables
        s = Step.new(step_params
                       .symbolize_keys
                       .slice(:name, :position, :description, :tables_attributes)
                       .merge(user: @user, completed: false))

        # 'Manually' create assets here. "Accept nasted attributes" won't work for assets
        s.assets << AttachmentsBuilder.generate(step_params.deep_symbolize_keys, user: @user, team: @team)
        s
      end

      @errors[:protocol] = @protocol.errors.messages unless @protocol.save

      self
    end

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
