# frozen_string_literal: true

require 'rails_helper'

describe Protocols::ImportProtocolFromClientService do
  let(:user) { create :user }
  let(:team) { create :team }
  let(:service_call) do
    Protocols::ImportProtocolFromClientService
      .call(protocol_client_id: 'id', protocol_source: 'protocolsio/v3', user_id: user.id, team_id: team.id)
  end
  let(:normalized_response) do
    JSON.parse(file_fixture('protocols_importer/protocols_io/v3/normalized_single_protocol.json').read)
        .to_h.with_indifferent_access
  end

  context 'when have invalid arguments' do
    it 'returns an error when can\'t find user' do
      allow(User).to receive(:find).and_return(nil)

      expect(service_call.errors).to have_key(:invalid_arguments)
    end
  end

  context 'when have valid arguments' do
    before do
      allow_any_instance_of(ProtocolImporters::ProtocolsIO::V3::ProtocolNormalizer)
        .to(receive(:load_protocol).and_return(normalized_response))
      # Do not generate and request real images
      allow(ProtocolImporters::AttachmentsBuilder).to(receive(:generate).and_return([]))
    end
    it 'Adds Protocol record' do
      expect { service_call }.to(change { Protocol.all.count }.by(1))
    end
    # more tests will be implemented when add error handling to service
  end
end
