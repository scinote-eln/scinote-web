# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::SearchProtocolsService do
  let(:service_call) do
    ProtocolImporters::SearchProtocolsService.call(protocol_source: 'protocolsio/v3',
                                                   query_params: {
                                                     key: 'someting',
                                                     page_id: 5,
                                                     order_field: 'title',
                                                     order_dir: 'asc'
                                                   })
  end

  let(:service_call_with_wrong_params) do
    ProtocolImporters::SearchProtocolsService.call(protocol_source: 'protocolsio3',
                                                   query_params: {
                                                     key: '',
                                                     page_id: -1,
                                                     order_field: 'gender',
                                                     order_dir: 'descc'
                                                   })
  end
  let(:normalized_list) do
    JSON.parse(file_fixture('protocol_importers/normalized_list.json').read).to_h.with_indifferent_access
  end

  context 'when have invalid attributes' do
    it 'returns an error when params are invalid' do
      expect(service_call_with_wrong_params.errors).to have_key(:invalid_params)
    end
  end

  context 'when raise api client error' do
    it 'return api errors' do
      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ApiClient)
        .to(receive(:protocol_list)
        .and_raise(ProtocolImporters::ProtocolsIo::V3::ArgumentError
          .new(:missing_or_empty_parameters), 'Missing Or Empty Parameters Error'))

      expect(service_call.errors).to have_key(:missing_or_empty_parameters)
    end
  end

  context 'when normalize protocol fails' do
    it 'return normalizer errors' do
      client_data = double('api_response')

      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ApiClient)
        .to(receive(:protocol_list)
        .and_return(client_data))

      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ProtocolNormalizer)
        .to(receive(:normalize_list).with(client_data)
        .and_raise(ProtocolImporters::ProtocolsIo::V3::NormalizerError.new(:nil_protocol), 'Nil Protocol'))

      expect(service_call.errors).to have_key(:nil_protocol)
    end
  end

  context 'when have valid attributes' do
    before do
      client_data = double('api_response')

      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ApiClient)
        .to(receive(:protocol_list)
              .and_return(client_data))

      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ProtocolNormalizer)
        .to(receive(:normalize_list).with(client_data)
              .and_return(normalized_list))
    end

    it 'returns normalized list' do
      expect(service_call.protocols_list).to be == normalized_list
    end
  end
end
