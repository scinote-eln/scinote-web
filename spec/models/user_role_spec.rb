require 'rails_helper'

RSpec.describe UserRole, type: :model do
  it 'should be of class UserRole' do
    expect(subject.class).to eq UserRole
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :permissions }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    before { allow(subject).to receive(:predefined?).and_return(true) }
    it { should have_many :user_assignments }
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :permissions }
  end
end
