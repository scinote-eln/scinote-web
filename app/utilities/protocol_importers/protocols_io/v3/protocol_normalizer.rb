# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIO
    module V3
      class ProtocolNormalizer < ProtocolImporters::ProtocolNormalizer
        def normalize_protocol(client_data)
          # client_data is HttpParty ApiReponse object
          protocol_hash = client_data.parsed_response.with_indifferent_access[:protocol]

          normalized_data = {
            uri: client_data.request.last_uri.to_s,
            source: Constants::PROTOCOLS_IO_V3_API[:source_id],
            doi: protocol_hash[:doi],
            published_on: protocol_hash[:published_on],
            version: protocol_hash[:version_id],
            source_id: protocol_hash[:id],
            name: protocol_hash[:title],
            description: {
              body: protocol_hash[:description],
              image: protocol_hash[:image][:source]
            },
            authors: protocol_hash[:authors].map { |e| e[:name] }.join(', ')
          }

          normalized_data[:steps] = protocol_hash[:steps].map do |e|
            {
              source_id: e[:id],
              name: StepComponents.name(e[:components]),
              attachments: StepComponents.attachments(e[:components]),
              description: {
                body: StepComponents.description(e[:components]),
                components: StepComponents.description_components(e[:components])
              },
              position: e[:previous_id].nil? ? 0 : nil
            }
          end

          # set positions
          first_step_id = normalized_data[:steps].find { |s| s[:position].zero? }[:source_id]
          next_step_id = protocol_hash[:steps].find { |s| s[:previous_id] == first_step_id }.try(:[], :id)
          steps = normalized_data[:steps].map { |s| [s[:source_id], s] }.to_h
          original_order = protocol_hash[:steps].map { |m| [m[:previous_id], m[:id]] }.to_h
          current_position = 0
          while next_step_id
            current_position += 1
            steps[next_step_id][:position] = current_position
            next_step_id = original_order[next_step_id]
          end

          { protocol: normalized_data }
        end

        def normalize_list(client_data)
          # client_data is HttpParty ApiReponse object
          protocols_hash = client_data.parsed_response.with_indifferent_access[:items]
          normalized_data = {}
          normalized_data[:protocols] = protocols_hash.map do |e|
            {
              "id": e[:id],
              "title": e[:title],
              "created_on": e[:created_on],
              "authors": e[:authors].map { |a| a[:name] }.join(', '),
              "nr_of_steps": e[:stats][:number_of_steps],
              "nr_of_views": e[:stats][:number_of_views],
              "uri": e[:uri]
            }
          end
          normalized_data
        end
      end
    end
  end
end
