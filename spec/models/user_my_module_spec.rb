require 'rails_helper'

describe UserMyModule, type: :model do
  it 'should be of class UserMyModule' do
    expect(subject.class).to eq UserMyModule
  end

  describe 'Database table' do
    it { should have_db_column :user_id }
    it { should have_db_column :my_module_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :assigned_by_id }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :my_module }
    it { should belong_to(:assigned_by).class_name('User') }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :user }
    it { should validate_presence_of :my_module }
  end
end
