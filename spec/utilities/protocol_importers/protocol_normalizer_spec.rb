# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ProtocolNormalizer do
  describe '.load_all_protocols' do
    it { expect { subject.load_all_protocols({}) }.to raise_error(NotImplementedError) }
  end

  describe '.load_protocol' do
    it { expect { subject.load_protocol({}) }.to raise_error(NotImplementedError) }
  end
end
