# frozen_string_literal: true

require 'rails_helper'

describe Asset, type: :model do
  let(:asset) { build :asset }

  it 'should be of class Asset' do
    expect(subject.class).to eq Asset
  end

  it 'is valid' do
    expect(asset).to be_valid
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :estimated_size }
    it { should have_db_column :lock }
    it { should have_db_column :lock_ttl }
    it { should have_db_column :version }
    it { should have_db_column :file_processing }
    it { should have_db_column :team_id }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should belong_to(:team).optional }
    it { should have_many :report_elements }
    it { should have_one :step_asset }
    it { should have_one :step }
    it { should have_one :result_asset }
    it { should have_one :result }
    it { should have_one :asset_text_datum }
    it { should have_one :repository_asset_value }
    it { should have_one :repository_cell }
  end
end
