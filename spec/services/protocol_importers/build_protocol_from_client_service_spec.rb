# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::BuildProtocolFromClientService do
  let(:user) { create :user }
  let(:team) { create :team }
  let(:service_call) do
    ProtocolImporters::BuildProtocolFromClientService
      .call(protocol_client_id: 'id', protocol_source: 'protocolsio/v3', user_id: user.id, team_id: team.id)
  end
  let(:normalized_response) do
    JSON.parse(file_fixture('protocol_importers/normalized_single_protocol.json').read)
        .to_h.with_indifferent_access
  end

  context 'when have invalid arguments' do
    it 'returns an error when can\'t find user' do
      allow(User).to receive(:find).and_return(nil)

      expect(service_call.errors).to have_key(:invalid_arguments)
    end
  end

  context 'when raise api client error' do
    it 'return network errors' do
      allow_any_instance_of(ProtocolImporters::ProtocolsIO::V3::ApiClient)
        .to(receive(:single_protocol)
        .and_raise(SocketError))

      expect(service_call.errors).to have_key(:socketerror)
    end

    it 'return api errors' do
      allow_any_instance_of(ProtocolImporters::ProtocolsIO::V3::ApiClient)
        .to(receive(:single_protocol)
        .and_raise(ProtocolImporters::ProtocolsIO::V3::ApiErrors::MissingOrEmptyParametersError.new('1', 'Missing Or Empty Parameters Error')))

      expect(service_call.errors).to have_key(:"protocolimporters::protocolsio::v3::apierrors::missingoremptyparameterserror")
    end
  end

  context 'when normalize protocol fails' do
    it 'return normalizer errors' do
      client_data = double('api_response')

      allow_any_instance_of(ProtocolImporters::ProtocolsIO::V3::ApiClient)
        .to(receive(:single_protocol)
        .and_return(client_data))

      allow_any_instance_of(ProtocolImporters::ProtocolsIO::V3::ProtocolNormalizer)
        .to(receive(:normalize_protocol).with(client_data)
        .and_raise(ProtocolImporters::ProtocolsIO::V3::NormalizerError.new('nil_protocol', 'Nil Protocol')))

      expect(service_call.errors).to have_key(:"protocolimporters::protocolsio::v3::normalizererror")
    end
  end

  context 'when have valid arguments' do
    before do
      client_data = double('api_response')

      allow_any_instance_of(ProtocolImporters::ProtocolsIO::V3::ApiClient)
        .to(receive(:single_protocol)
        .and_return(client_data))

      allow_any_instance_of(ProtocolImporters::ProtocolsIO::V3::ProtocolNormalizer)
        .to(receive(:normalize_protocol).with(client_data)
        .and_return(normalized_response))

      # Do not generate and request real images
      allow(ProtocolImporters::AttachmentsBuilder).to(receive(:generate).and_return([]))
    end

    it 'returns ProtocolIntermediateObject' do
      expect(service_call.built_protocol).to be_instance_of(Protocol)
    end
    # more tests will be implemented when add error handling to service
  end
end
