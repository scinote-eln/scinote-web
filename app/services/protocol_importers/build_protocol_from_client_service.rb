# frozen_string_literal: true

module ProtocolImporters
  class BuildProtocolFromClientService
    extend Service

    attr_reader :errors, :built_protocol, :steps_assets

    def initialize(protocol_client_id:, protocol_source:, user_id:, team_id:, build_with_assets: true)
      @id = protocol_client_id
      @protocol_source = protocol_source
      @user = User.find_by_id user_id
      @team = Team.find_by_id team_id
      @build_with_assets = build_with_assets
      @steps_assets = {}
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
                                                              team: @team,
                                                              build_with_assets: @build_with_assets)

      @built_protocol = pio.build
      @steps_assets = pio.steps_assets unless @build_with_assets

      self
    rescue client_errors => e
      @errors[e.error_type] = e.message
      self
    end

    def succeed?
      @errors.none?
    end

    def serialized_steps
      # Serialize steps with nested attributes for Tables and NOT nasted attributes for Assets
      # We want to avoid creating (downloading) Assets instances on building first time and again on importing/creating,
      # when both actions are not in a row.
      return nil unless built_protocol

      built_protocol.steps.map do |step|
        step_hash = step.attributes.symbolize_keys.slice(:name, :description, :position)

        if !@build_with_assets && @steps_assets[step.position].any?
          step_hash[:attachments] = @steps_assets[step.position]
        end

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

    def client_errors
      "ProtocolImporters::#{endpoint_name}::Error".constantize
    end
  end
end
