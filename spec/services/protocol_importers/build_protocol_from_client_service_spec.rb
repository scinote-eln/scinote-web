# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::BuildProtocolFromClientService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:service_call) do
    ProtocolImporters::BuildProtocolFromClientService
      .call(protocol_client_id: 'id', protocol_source: 'protocolsio/v3', user_id: user.id, team_id: team.id)
  end
  let(:service_call_without_assets) do
    ProtocolImporters::BuildProtocolFromClientService
      .call(protocol_client_id: 'id',
            protocol_source: 'protocolsio/v3',
            user_id: user.id,
            team_id: team.id,
            build_with_assets: false)
  end
  let(:normalized_response) do
    JSON.parse(file_fixture('protocol_importers/normalized_single_protocol.json').read)
        .to_h.with_indifferent_access
  end

  context 'when have invalid arguments' do
    it 'returns an error when can\'t find user' do
      allow(User).to receive(:find_by_id).and_return(nil)

      expect(service_call.errors).to have_key(:invalid_arguments)
    end
  end

  context 'when raise api client error' do
    it 'return api errors' do
      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ApiClient)
        .to(receive(:single_protocol)
        .and_raise(ProtocolImporters::ProtocolsIo::V3::ArgumentError
          .new(:missing_or_empty_parameters), 'Missing Or Empty Parameters Error'))

      expect(service_call.errors).to have_key(:missing_or_empty_parameters)
    end
  end

  context 'when normalize protocol fails' do
    it 'return normalizer errors' do
      client_data = double('api_response')

      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ApiClient)
        .to(receive(:single_protocol)
        .and_return(client_data))

      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ProtocolNormalizer)
        .to(receive(:normalize_protocol).with(client_data)
        .and_raise(ProtocolImporters::ProtocolsIo::V3::NormalizerError.new(:nil_protocol), 'Nil Protocol'))

      expect(service_call.errors).to have_key(:nil_protocol)
    end
  end

  context 'when have valid arguments' do
    before do
      client_data = double('api_response')

      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ApiClient)
        .to(receive(:single_protocol)
        .and_return(client_data))

      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ProtocolNormalizer)
        .to(receive(:normalize_protocol).with(client_data)
        .and_return(normalized_response))

      # Do not generate and request real images
      allow(ProtocolImporters::AttachmentsBuilder).to(receive(:generate).and_return([]))
    end

    it 'returns ProtocolIntermediateObject' do
      expect(service_call.built_protocol).to be_instance_of(Protocol)
    end
    # more tests will be implemented when add error handling to service

    describe 'serialized_steps' do
      context 'when build without assets' do
        it 'returns JSON with attachments' do
          expect(JSON.parse(service_call_without_assets.serialized_steps).first).to have_key('attachments')
        end
      end
    end
  end
end
