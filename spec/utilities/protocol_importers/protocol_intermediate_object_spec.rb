# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ProtocolIntermediateObject do
  subject(:pio) { described_class.new(normalized_json: normalized_result, user: user, team: team) }
  let(:invalid_pio) { described_class.new(normalized_json: normalized_result, user: nil, team: team) }
  let(:user) { create :user }
  let(:team) { create :team }
  let(:normalized_result) do
    JSON.parse(file_fixture('protocol_importers/normalized_single_protocol.json').read)
        .to_h.with_indifferent_access
  end

  before do
    stub_request(:get, 'https://pbs.twimg.com/media/Cwu3zrZWQAA7axs.jpg').to_return(status: 200, body: '', headers: {})
    stub_request(:get, 'http://something.com/wp-content/uploads/2014/11/14506718045_5b3e71dacd_o.jpg')
      .to_return(status: 200, body: '', headers: {})
  end

  describe '.build' do
    it { expect(subject.build).to be_instance_of(Protocol) }
  end

  describe '.import' do
    context 'when have valid object' do
      it { expect { pio.import }.to change { Protocol.all.count }.by(1) }
      it { expect { pio.import }.to change { Step.all.count }.by(2) }
      it { expect { pio.import }.to change { Asset.all.count }.by(2) }
      it { expect(pio.import).to be_valid }
    end

    context 'when have invalid object' do
      it { expect(invalid_pio.import).to be_invalid }
      it { expect { invalid_pio.import }.not_to(change { Protocol.all.count }) }
    end
  end
end
