# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ImportProtocolService do
  let(:user) { create :user }
  let(:team) { create :team }
  let(:protocol_params) { attributes_for :protocol, :in_public_repository }
  let(:steps_params) do
    [
      attributes_for(:step).merge!(attachments: [{ name: 'random.jpg', url: 'http://www.example.com/random.jpg' }]),
      attributes_for(:step).merge!(tables_attributes: [attributes_for(:table), attributes_for(:table)])
    ].to_json
  end

  let(:service_call) do
    ProtocolImporters::ImportProtocolService
      .call(protocol_params: protocol_params, steps_params_json: steps_params, user_id: user.id, team_id: team.id)
  end

  context 'when have invalid arguments' do
    it 'returns an error when can\'t find user' do
      allow(User).to receive(:find_by_id).and_return(nil)

      expect(service_call.errors).to have_key(:invalid_arguments)
    end

    it 'returns invalid protocol when can\'t save it' do
      # step with file without name
      steps_invalid_params = [
        attributes_for(:step).except(:name).merge!(tables_attributes: [attributes_for(:table)])
      ].to_json

      s = ProtocolImporters::ImportProtocolService.call(protocol_params: protocol_params,
                                                        steps_params_json: steps_invalid_params,
                                                        user_id: user.id, team_id: team.id)
      expect(s.protocol).to be_invalid
    end
  end

  context 'when have valid arguments' do
    before do
      stub_request(:get, 'http://www.example.com/random.jpg').to_return(status: 200, body: '', headers: {})

      @protocol = Protocol.new
    end

    # rubocop:disable MultilineMethodCallIndentation
    it do
      expect do
        service_result = service_call
        @protocol = service_result.protocol
      end.to change { Protocol.all.count }.by(1)
         .and change { @protocol.steps.count }.by(2)
         .and change { Table.joins(:step_table).where('step_tables.step_id': @protocol.steps.pluck(:id)).count }.by(2)
         .and change { Asset.joins(:step_asset).where('step_assets.step_id': @protocol.steps.pluck(:id)).count }.by(1)
    end
    # rubocop:enable MultilineMethodCallIndentation
  end
end
