# frozen_string_literal: true

module ProtocolImporters
  class ProtocolIntermediateObject
    attr_accessor :normalized_response, :user, :team

    def initialize(normalized_json: {}, user:, team:)
      @normalized_response = normalized_json[:protocol] if normalized_json
      @user = user
      @team = team
    end

    def import
      p = build
      p.save if p.valid?
      p
    end

    def build
      p = build_protocol
      p.steps << build_steps
      p
    end

    private

    def build_protocol
      Protocol.new(protocol_attributes)
    end

    def build_steps
      # TODO
      # Add:
      # - Assets
      # - Tables
      # - Checklists

      @normalized_response[:steps].map do |s|
        Step.new(step_attributes(s))
      end
    end

    def protocol_attributes
      defaults = { protocol_type: :in_repository_public, added_by: @user, team: @team }
      values = %i(name published_on description authors)
      p_attrs = @normalized_response.slice(*values).each_with_object({}) do |(k, v), h|
        h[k] = k == 'published_on' ? Time.at(v) : v
      end
      p_attrs.merge!(defaults)
    end

    def step_attributes(step_json)
      defaults = { user: @user, completed: false }
      step_json.slice(:name, :position, :description).merge!(defaults)
    end
  end
end
