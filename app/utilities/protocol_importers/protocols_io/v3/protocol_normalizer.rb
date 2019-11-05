# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIo
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
              image: protocol_hash[:image][:source],
              extra_content: []
            },
            authors: protocol_hash[:authors].map { |e| e[:name] }.join(', ')
          }

          { before_start: 'Before start', guidelines: 'Guidelines', warning: 'Warnings' }.each do |k, v|
            normalized_data[:description][:extra_content] << { title: v, body: protocol_hash[k] } if protocol_hash[k]
          end

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
          if protocol_hash[:steps].any?
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

            # Check if step name are valid
            steps.each do |step|
              step[1][:name] = "Step #{(step[1][:position] + 1)}" if step[1][:name].blank?
            end
          else
            normalized_data[:steps] = []
          end

          { protocol: normalized_data }
        rescue StandardError => e
          raise ProtocolImporters::ProtocolsIo::V3::NormalizerError.new(e.class.to_s.downcase.to_sym), e.message
        end

        def normalize_list(client_data)
          # client_data is HttpParty ApiReponse object
          protocols_hash = client_data.parsed_response.with_indifferent_access[:items]
          pagination = client_data.parsed_response.with_indifferent_access[:pagination]

          if client_data.parsed_response[:local_sorting]
            protocols_hash =
              case client_data.parsed_response[:local_sorting]
              when 'alpha_asc'
                protocols_hash.sort_by { |p| p[:title] }
              when 'alpha_desc'
                protocols_hash.sort_by { |p| p[:title] }.reverse
              when 'oldest'
                protocols_hash.sort_by { |p| p[:created_on] }
              else
                protocols_hash.sort_by { |p| p[:created_on] }.reverse
              end
          end

          normalized_data = {}
          normalized_data[:protocols] = protocols_hash.map do |e|
            {
              id: e[:id],
              title: e[:title],
              source: Constants::PROTOCOLS_IO_V3_API[:source_id],
              created_on: e[:created_on],
              published_on: e[:published_on],
              authors: e[:authors].map { |a| a[:name] }.join(', '),
              nr_of_steps: e[:stats][:number_of_steps],
              nr_of_views: e[:stats][:number_of_views],
              uri: e[:uri]
            }
          end

          # Parse pagination
          normalized_data[:pagination] =
            if pagination
              {
                current_page: pagination[:current_page],
                total_pages: pagination[:total_pages],
                page_size: pagination[:page_size]
              }
            else
              {
                current_page: 1,
                total_pages: 1,
                page_size: 0
              }
            end

          normalized_data
        rescue StandardError => e
          raise ProtocolImporters::ProtocolsIo::V3::NormalizerError.new(e.class.to_s.downcase.to_sym), e.message
        end
      end
    end
  end
end
