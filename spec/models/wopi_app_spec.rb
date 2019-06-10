# frozen_string_literal: true

require 'rails_helper'

describe WopiApp, type: :model do
  let(:wopi_app) { build :wopi_app }

  it 'is valid' do
    expect(wopi_app).to be_valid
  end

  it 'should be of class WopiApp' do
    expect(subject.class).to eq WopiApp
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :icon }
    it { should have_db_column :wopi_discovery_id }
  end

  describe 'Relations' do
    it { should belong_to :wopi_discovery }
    it { should have_many :wopi_actions }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :icon }
    it { should validate_presence_of :wopi_discovery }
  end
end
