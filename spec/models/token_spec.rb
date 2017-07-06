require 'rails_helper'

describe Token, type: :model do
  it 'should be of class Token' do
    expect(subject.class).to eq Token
  end

  describe 'Database table' do
    it { should have_db_column :token }
    it { should have_db_column :ttl }
    it { should have_db_column :user_id }
  end

  describe 'Relations' do
    it { should belong_to :user }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :token }
    it { should validate_presence_of :ttl }
  end
end
