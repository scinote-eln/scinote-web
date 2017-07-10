require 'rails_helper'

describe SampleType, type: :model do
  it 'should be of class SampleType' do
    expect(subject.class).to eq SampleType
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :team_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_many :samples }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :team }
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end
    it { should validate_uniqueness_of(:name).scoped_to(:team).case_insensitive }
  end
end
