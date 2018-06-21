require 'rails_helper'

describe Asset, type: :model do
  it 'should be of class Asset' do
    expect(subject.class).to eq Asset
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :file_file_name }
    it { should have_db_column :file_content_type }
    it { should have_db_column :file_file_size }
    it { should have_db_column :file_updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :estimated_size }
    it { should have_db_column :file_present }
    it { should have_db_column :lock }
    it { should have_db_column :lock_ttl }
    it { should have_db_column :version }
    it { should have_db_column :file_processing }
    it { should have_db_column :team_id }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should belong_to :team }
    it { should have_many :report_elements }
    it { should have_one :step_asset }
    it { should have_one :step }
    it { should have_one :result_asset }
    it { should have_one :result }
    it { should have_one :asset_text_datum }
    it { should have_one :repository_asset_value }
    it { should have_one :repository_cell }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :file }
    it 'should validate the presence of estimated size' do
      asset = build :asset, estimated_size: nil
      expect(asset).to_not be_valid
    end
    #  should validate_presence_of :estimated_size }
    it { should validate_inclusion_of(:file_present).in_array([true, false]) }
  end
end
