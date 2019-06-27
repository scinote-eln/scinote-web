# frozen_string_literal: true

module ProtocolImporters
  class ProtocolIntermediateObject
    attr_reader :normalized_protocol_data, :user, :team, :protocol, :steps_assets, :build_with_assets

    def initialize(normalized_json: {}, user:, team:, build_with_assets: true)
      @normalized_protocol_data = normalized_json.with_indifferent_access[:protocol] if normalized_json
      @user = user
      @team = team
      @steps_assets = {}
      @build_with_assets = build_with_assets
    end

    def import
      build unless @protocol
      @protocol.save
      @protocol
    end

    def build
      @protocol = Protocol.new(protocol_attributes)
      @protocol.description = ProtocolDescriptionBuilder.generate(@normalized_protocol_data)
      @protocol.steps << build_steps
      @protocol
    end

    private

    def build_steps
      @normalized_protocol_data[:steps].map do |s|
        step = Step.new(step_attributes(s))
        if @build_with_assets
          step.assets << AttachmentsBuilder.generate(s, user: user, team: team)
        else
          @steps_assets[step.position] = AttachmentsBuilder.generate_json(s)
        end
        step.tables << TablesBuilder.extract_tables_from_html_string(s[:description][:body], true)
        step.description = StepDescriptionBuilder.generate(s)
        step
      end
    end

    def protocol_attributes
      {
        protocol_type: :in_repository_public,
        added_by: @user,
        team: @team,
        name: @normalized_protocol_data[:name],
        published_on: Time.at(@normalized_protocol_data[:published_on]),
        authors: @normalized_protocol_data[:authors]
      }
    end

    def step_attributes(step_json)
      defaults = { user: @user, completed: false }
      step_json.slice(:name, :position).merge!(defaults)
    end
  end
end
