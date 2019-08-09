# frozen_string_literal: true

module ProtocolImporters
  module AttachmentsBuilder
    def self.generate(step_json, user: nil, team: nil)
      return [] unless step_json[:attachments]&.any?

      step_json[:attachments].map do |f|
        Asset.new(file:  URI.parse(f[:url]),
                  created_by: user,
                  last_modified_by: user,
                  team: team,
                  file_file_name: f[:name])
      end
    end

    def self.generate_json(step_json)
      return [] unless step_json[:attachments]&.any?

      step_json[:attachments].map do |f|
        {
          name: f[:name],
          url: f[:url]
        }
      end
    end
  end
end
