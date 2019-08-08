# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ProtocolNormalizer do
  describe '.normalize_list' do
    it { expect { subject.normalize_list({}) }.to raise_error(NotImplementedError) }
  end

  describe '.normalize_protocol' do
    it { expect { subject.normalize_protocol({}) }.to raise_error(NotImplementedError) }
  end
end
