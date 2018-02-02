require 'rails_helper'

describe TinyMceAsset, type: :model do
  it 'should be of class TinyMceAsset' do
    expect(subject.class).to eq TinyMceAsset
  end

  describe 'Database table' do
    it { should have_db_column :image_file_name }
    it { should have_db_column :image_content_type }
    it { should have_db_column :image_file_size }
    it { should have_db_column :image_updated_at }
    it { should have_db_column :estimated_size }
    it { should have_db_column :step_id }
    it { should have_db_column :team_id }
    it { should have_db_column :result_text_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should belong_to :step }
    it { should belong_to :result_text }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :estimated_size }
  end
end
