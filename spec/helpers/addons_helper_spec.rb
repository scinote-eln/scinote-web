# frozen_string_literal: true

require 'rails_helper'

describe AddonsHelper, type: :helper do
  describe '#list_all_addons' do
    it 'returns the parent modules of the engines whose names start with Scinote' do
      scinote_engine = stub_const('ScinoteFakeAddon::Engine', Class.new)
      other_engine = stub_const('OtherFakeAddon::Engine', Class.new)
      allow(Rails::Engine).to receive(:subclasses).and_return([scinote_engine, other_engine])

      expect(helper.list_all_addons).to eq [ScinoteFakeAddon]
    end

    it 'returns an empty list when no scinote engines are loaded' do
      other_engine = stub_const('OtherFakeAddon::Engine', Class.new)
      allow(Rails::Engine).to receive(:subclasses).and_return([other_engine])

      expect(helper.list_all_addons).to eq []
    end
  end
end
