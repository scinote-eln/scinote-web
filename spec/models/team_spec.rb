require 'rails_helper'

describe Team, type: :model do
  it 'should be of class Team' do
    expect(subject.class).to eq Team
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :description }
    it { should have_db_column :space_taken }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_many :user_teams }
    it { should have_many :users }
    it { should have_many :samples }
    it { should have_many :samples_tables }
    it { should have_many :sample_groups }
    it { should have_many :sample_types }
    it { should have_many :projects }
    it { should have_many :custom_fields }
    it { should have_many :protocols }
    it { should have_many :protocol_keywords }
    it { should have_many :tiny_mce_assets }
    it { should have_many :repositories }
    it { should have_many :reports }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :space_taken }
    it do
      should validate_length_of(:name)
               .is_at_least(Constants::NAME_MIN_LENGTH)
               .is_at_most(Constants::NAME_MAX_LENGTH)
    end
    it do
      should validate_length_of(:description)
               .is_at_most(Constants::TEXT_MAX_LENGTH)
    end
  end
end
