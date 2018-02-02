require 'rails_helper'

describe TempFile, type: :model do
  it 'should be of class TempFile' do
    expect(subject.class).to eq TempFile
  end

  describe 'Database table' do
    it { should have_db_column :session_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :file_file_name }
    it { should have_db_column :file_content_type }
    it { should have_db_column :file_file_size }
    it { should have_db_column :file_updated_at }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :session_id }
  end
end
