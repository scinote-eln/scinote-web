# frozen_string_literal: true

require 'rails_helper'

describe WopiDiscovery, type: :model do
  let(:wopi_discovery) { build :wopi_discovery }

  it 'is valid' do
    expect(wopi_discovery).to be_valid
  end

  it 'should be of class WopiDiscovery' do
    expect(subject.class).to eq WopiDiscovery
  end

  describe 'Database table' do
    it { should have_db_column :expires }
    it { should have_db_column :proof_key_mod }
    it { should have_db_column :proof_key_exp }
    it { should have_db_column :proof_key_old_mod }
    it { should have_db_column :proof_key_old_exp }
  end

  describe 'Relations' do
    it { should have_many :wopi_apps }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :expires }
    it { should validate_presence_of :proof_key_mod }
    it { should validate_presence_of :proof_key_exp }
    it { should validate_presence_of :proof_key_old_mod }
    it { should validate_presence_of :proof_key_old_exp }
  end
end
