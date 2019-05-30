# frozen_string_literal: true

module Protocols
  class ImportProtocolFromClientService
    extend Service

    attr_reader :errors, :pio_protocol

    def initialize(protocol_client_id:, protocol_source:, user_id:, team_id:)
      @id = protocol_client_id
      @protocol_source = protocol_source
      @user = User.find user_id
      @team = Team.find team_id
      @errors = {}
    end

    def call
      return self unless valid?

      # Catch api errors here, json invalid, also wrong/not found normalizer?
      normalized_hash = client.load_protocol(id: @id)
      # Catch api errors here

      pio = ProtocolImporters::ProtocolIntermediateObject.new(normalized_json: normalized_hash,
                                                              user: @user,
                                                              team: @team)
      @pio_protocol = pio.build

      if @pio_protocol.valid?
        # catch errors during import here
        pio.import
        # catch errors during import here
      else
        # Add AR errors here
        # @errors[:protcol] = pio.protocol.errors.to_json...? somehow
        @errors[:protocol] = pio.protocol.errors
      end

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      unless @id && @protocol_source && @user && @team
        @errors[:invalid_arguments] = { '@id': @id, '@protocol_source': @protocol_source, 'user': @user, 'team': @team }
                                      .map { |key, value| "Can't find #{key.capitalize}" if value.nil? }.compact
        return false
      end
      true
    end

    def client
      endpoint_name = Constants::PROTOCOLS_ENDPOINTS.dig(*@protocol_source.split('/').map(&:to_sym))
      "ProtocolImporters::#{endpoint_name}::ProtocolNormalizer".constantize.new
    end
  end
end
