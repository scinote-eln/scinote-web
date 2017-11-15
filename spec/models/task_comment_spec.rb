require 'rails_helper'

describe TaskComment, type: :model do
  it 'should be of class TaskComment' do
    expect(subject.class).to eq TaskComment
  end

  describe 'Database table' do
    it { should have_db_column :message }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :type }
    it { should have_db_column :associated_id }
  end

  describe 'Relations' do
    it { should belong_to :my_module }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :my_module }
  end
end
