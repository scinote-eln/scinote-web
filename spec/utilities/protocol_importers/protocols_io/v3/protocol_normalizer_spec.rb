# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ProtocolsIO::V3::ProtocolNormalizer do
  let(:response) do
    JSON.parse(file_fixture('protocol_importers/protocols_io/v3/single_protocol.json').read)
        .to_h.with_indifferent_access
  end

  let(:response_without_title) do
    res_without_title = response
    res_without_title[:protocol].reject! { |a| a == 'title' }
    res_without_title
  end

  let(:normalized_result) do
    JSON.parse(file_fixture('protocol_importers/normalized_single_protocol.json').read)
        .to_h.with_indifferent_access
  end

  describe '#load_protocol' do
    before do
      allow_any_instance_of(ProtocolImporters::ProtocolsIO::V3::ApiClient)
        .to(receive_message_chain(:single_protocol, :request, :last_uri, :to_s)
              .and_return('https://www.protocols.io/api/v3/protocols/9451'))
    end

    context 'when have all data' do
      it 'should normalize data correctly' do
        allow_any_instance_of(ProtocolImporters::ProtocolsIO::V3::ApiClient)
          .to receive_message_chain(:single_protocol, :parsed_response).and_return(response)

        expect(subject.load_protocol(id: 'id').deep_stringify_keys).to be == normalized_result
      end
    end

    context 'when do not have name' do
      it 'sets nil for name' do
        allow_any_instance_of(ProtocolImporters::ProtocolsIO::V3::ApiClient)
          .to receive_message_chain(:single_protocol, :parsed_response).and_return(response_without_title)

        expect(subject.load_protocol(id: 'id')[:protocol][:name]).to be_nil
      end
    end
  end
end
