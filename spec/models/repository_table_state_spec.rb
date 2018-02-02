require 'rails_helper'

describe RepositoryTableState, type: :model do
  it 'should be of class RepositoryTableState' do
    expect(subject.class).to eq RepositoryTableState
  end

  describe 'Database table' do
    it { should have_db_column :state }
    it { should have_db_column :user_id }
    it { should have_db_column :repository_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :repository }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :user }
    it { should validate_presence_of :repository }
  end
end
