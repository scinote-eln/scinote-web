require 'rails_helper'

describe ProtocolProtocolKeyword, type: :model do
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

  describe 'Should be a valid object' do
    it { should validate_presence_of :protocol }
    it { should validate_presence_of :protocol_keyword }
  end
end
