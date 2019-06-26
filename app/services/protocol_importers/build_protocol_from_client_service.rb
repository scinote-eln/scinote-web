# frozen_string_literal: true

module ProtocolImporters
  class BuildProtocolFromClientService
    extend Service
    require 'protocol_importers/protocols_io/v3/errors'

    attr_reader :errors, :built_protocol

    def initialize(protocol_client_id:, protocol_source:, user_id:, team_id:)
      @id = protocol_client_id
      @protocol_source = protocol_source
      @user = User.find user_id
      @team = Team.find team_id
      @errors = {}
    end

    def call
      return self unless valid?

      # Call api client
      api_response = api_client.single_protocol(@id)

      # Normalize protocol
      normalized_hash = normalizer.normalize_protocol(api_response)

      pio = ProtocolImporters::ProtocolIntermediateObject.new(normalized_json: normalized_hash,
                                                              user: @user,
                                                              team: @team)

      @built_protocol = pio.build
      # Protocol with AR errors should not handled here as someting whats wrong.
      # @errors[:protocol] = pio.protocol.errors unless @built_protocol.valid?
      self
    rescue api_errors => e
      @errors[e.error_type] = e.message
      self
    rescue normalizer_errors => e
      @errors[e.error_type] = e.message
      self
    rescue StandardError => e
      @errors[:build_protocol] = e.message
      self
    end

    def succeed?
      @errors.none?
    end

    def serialized_steps
      return nil unless built_protocol

      built_protocol.steps.map do |step|
        step_hash = step.attributes.symbolize_keys.slice(:name, :description, :position)

        # if step.assets.any?
        #   step_hash[:assets_attributes] = step.assets.map { |a| a.attributes.symbolize_keys.except(:id) }
        # end

        if step.tables.any?
          step_hash[:tables_attributes] = step.tables.map { |t| t.attributes.symbolize_keys.slice(:contents) }
        end

        step_hash
      end.to_json
    end

    private

    def valid?
      unless [@id, @protocol_source, @user, @team].all?
        @errors[:invalid_arguments] = {
          '@id': @id,
          '@protocol_source': @protocol_source,
          'user': @user,
          'team': @team
        }.map { |key, value| "Can't find #{key.capitalize}" if value.nil? }.compact
        return false
      end
      true
    end

    def endpoint_name
      Constants::PROTOCOLS_ENDPOINTS.dig(*@protocol_source.split('/').map(&:to_sym))
    end

    def api_client
      "ProtocolImporters::#{endpoint_name}::ApiClient".constantize.new
    end

    def normalizer
      "ProtocolImporters::#{endpoint_name}::ProtocolNormalizer".constantize.new
    end

    def api_errors
      "ProtocolImporters::#{endpoint_name}::Error".constantize
    end

    def normalizer_errors
      "ProtocolImporters::#{endpoint_name}::NormalizerError".constantize
    end
  end
end
