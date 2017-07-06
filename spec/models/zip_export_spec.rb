require 'rails_helper'

describe ZipExport, type: :model do
  it 'should be of class ZipExport' do
    expect(subject.class).to eq ZipExport
  end

  describe 'Database table' do
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :zip_file_file_name }
    it { should have_db_column :zip_file_content_type }
    it { should have_db_column :zip_file_file_size }
    it { should have_db_column :zip_file_updated_at }
  end

  describe 'Relations' do
    it { should belong_to :user }
  end
end
