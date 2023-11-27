require 'rails_helper'

RSpec.describe UserAssignment, type: :model do
  before do
    allow_any_instance_of(UserAssignment).to receive(:set_assignable_team)
  end

  it 'should be of class UserAssignment' do
    expect(subject.class).to eq UserAssignment
  end

  describe 'Database table' do
    it { should have_db_column :assignable_type }
    it { should have_db_column :assignable_id }
    it { should have_db_column :user_id }
    it { should have_db_column :user_role_id }
    it { should have_db_column :assigned_by_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:assignable).touch(true) }
    it { should belong_to :user }
    it { should belong_to :user_role }
    it { should belong_to(:assigned_by).class_name('User').optional }
  end
end
