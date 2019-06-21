# frozen_string_literal: true

require 'rails_helper'

describe ProtocolProtocolKeyword, type: :model do
  let(:protocol_protocol_keyword) { build :protocol_protocol_keyword }

  it 'is valid' do
    expect(protocol_protocol_keyword).to be_valid
  end

  it 'should be of class ProtocolProtocolKeyword' do
    expect(subject.class).to eq ProtocolProtocolKeyword
  end

  describe 'Database table' do
    it { should have_db_column :protocol_id }
    it { should have_db_column :protocol_keyword_id }
  end

  describe 'Relations' do
    it { should belong_to :protocol }
    it { should belong_to :protocol_keyword }
  end

  describe 'Validations' do
    it { should validate_presence_of :protocol }
    it { should validate_presence_of :protocol_keyword }
  end
end
