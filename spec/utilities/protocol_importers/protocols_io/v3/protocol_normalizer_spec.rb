# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ProtocolsIo::V3::ProtocolNormalizer do
  let(:client_data) { double('api_response') }

  let(:protocols_io_single_protocol) do
    JSON.parse(file_fixture('protocol_importers/protocols_io/v3/single_protocol.json').read)
        .to_h.with_indifferent_access
  end

  let(:response_without_title) do
    res_without_title = protocols_io_single_protocol
    res_without_title[:protocol].reject! { |a| a == 'title' }
    res_without_title
  end

  let(:protocols_io_list) do
    JSON.parse(file_fixture('protocol_importers/protocols_io/v3/protocols.json').read).to_h.with_indifferent_access
  end

  let(:normalized_protocol) do
    JSON.parse(file_fixture('protocol_importers/normalized_single_protocol.json').read).to_h.with_indifferent_access
  end

  let(:normalized_list) do
    JSON.parse(file_fixture('protocol_importers/normalized_list.json').read).to_h.with_indifferent_access
  end

  describe '#normalize_protocol' do
    before do
      allow(client_data).to(receive_message_chain(:request, :last_uri, :to_s)
                        .and_return('https://www.protocols.io/api/v3/protocols/9451'))
    end

    context 'when have all data' do
      it 'should normalize data correctly' do
        allow(client_data).to receive_message_chain(:parsed_response)
          .and_return(protocols_io_single_protocol)

        expect(subject.normalize_protocol(client_data).deep_stringify_keys).to be == normalized_protocol
      end
    end

    it 'raises NormalizerError if response is empty' do
      allow(client_data).to receive_message_chain(:parsed_response)
        .and_return({})

      expect { subject.normalize_protocol(client_data) }
        .to raise_error(ProtocolImporters::ProtocolsIo::V3::NormalizerError)
    end

    context 'when do not have name' do
      it 'sets nil for name' do
        allow(client_data).to receive_message_chain(:parsed_response)
          .and_return(response_without_title)

        expect(subject.normalize_protocol(client_data)[:protocol][:name]).to be_nil
      end
    end
  end

  describe '#normalize_list' do
    it 'should normalize data correctly' do
      allow(client_data).to receive_message_chain(:parsed_response).and_return(protocols_io_list)

      expect(subject.normalize_list(client_data).deep_stringify_keys).to be == normalized_list
    end

    it 'raises NormalizerError if response is empty' do
      allow(client_data).to receive_message_chain(:parsed_response)
        .and_return({})

      expect { subject.normalize_list(client_data) }
        .to raise_error(ProtocolImporters::ProtocolsIo::V3::NormalizerError)
    end
  end
end
