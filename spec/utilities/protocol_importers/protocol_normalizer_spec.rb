# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ProtocolNormalizer do
  describe '.load_all_protocols' do
    it { expect { subject.load_all_protocols }.to raise_error(NotImplementedError) }
    it { expect { subject.load_all_protocols(_params: 'some-params') }.to raise_error(NotImplementedError) }
  end

  describe '.load_protocol' do
    it { expect { subject.load_protocol(_id: 'random-id') }.to raise_error(NotImplementedError) }
    it { expect { subject.load_protocol(_id: 'random-id', _params: 'someparams') }.to raise_error(NotImplementedError) }
  end
end
