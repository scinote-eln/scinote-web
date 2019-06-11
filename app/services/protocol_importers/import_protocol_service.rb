# frozen_string_literal: true

module ProtocolImporters
  class ImportProtocolService
    extend Service

    attr_reader :errors, :protocol

    def initialize(protocol_params:, steps_params:, team_id:, user_id:)
      @user = User.find user_id
      @team = Team.find team_id
      @protocol_params = protocol_params
      @steps_params = steps_params
      @errors = {}
    end

    def call
      return self unless valid?

      @protocol = Protocol.new(@protocol_params.merge!(added_by: @user, team: @team))

      @protocol.steps << @steps_params.collect do |step_params|
        Step.new(step_params.merge(user: @user, completed: false))
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
