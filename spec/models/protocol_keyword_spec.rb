# frozen_string_literal: true

require 'rails_helper'

describe ProtocolKeyword, type: :model do
  let(:protocol_keyword) { build :protocol_keyword }

  it 'is valid' do
    expect(protocol_keyword).to be_valid
  end

  it 'should be of class ProtocolKeyword' do
    expect(subject.class).to eq ProtocolKeyword
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :nr_of_protocols }
    it { should have_db_column :team_id }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should have_many :protocol_protocol_keywords }
    it { should have_many :protocols }
  end

  describe 'Validations' do
    it { should validate_presence_of :team }
    it do
      should validate_length_of(:name)
        .is_at_least(Constants::NAME_MIN_LENGTH)
        .is_at_most(Constants::NAME_MAX_LENGTH)
    end
  end
end
