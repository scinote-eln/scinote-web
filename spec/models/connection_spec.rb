# frozen_string_literal: true

require 'rails_helper'

describe Connection, type: :model do
  let(:connection) { build :connection }

  it 'is valid' do
    expect(connection).to be_valid
  end

  it 'should be of class Connection' do
    expect(subject.class).to eq Connection
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:to).class_name('MyModule') }
    it { is_expected.to belong_to(:from).class_name('MyModule') }
  end
end
