# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ProtocolNormalizer do
  describe '.normalize_all_protocols' do
    it { expect { subject.normalize_all_protocols({}) }.to raise_error(NotImplementedError) }
  end

  describe '.normalize_protocols' do
    it { expect { subject.normalize_protocol({}) }.to raise_error(NotImplementedError) }
  end
end
