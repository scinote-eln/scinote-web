require 'rails_helper'

describe Activity, type: :model do
  it 'should be of class Activity' do
    expect(subject.class).to eq Activity
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :my_module_id }
    it { should have_db_column :user_id }
    it { should have_db_column :type_of }
    it { should have_db_column :message }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :project_id }
    it { should have_db_column :experiment_id }
  end

  describe 'Relations' do
    it { should belong_to :project }
    it { should belong_to :experiment }
    it { should belong_to :my_module }
    it { should belong_to :user }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :type_of }
  end
end
