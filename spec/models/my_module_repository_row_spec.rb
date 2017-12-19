require 'rails_helper'

describe MyModuleRepositoryRow, type: :model do
  it 'should be of class MyModuleRepositoryRow' do
    expect(subject.class).to eq MyModuleRepositoryRow
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :repository_row_id }
    it { should have_db_column :my_module_id }
    it { should have_db_column :assigned_by_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :my_module }
    it { should belong_to(:assigned_by).class_name('User') }
    it { should belong_to :repository_row }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :repository_row }
    it { should validate_presence_of :my_module }
  end
end
