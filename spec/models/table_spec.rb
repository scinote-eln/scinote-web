require 'rails_helper'

describe Table, type: :model do
  it 'should be of class Table' do
    expect(subject.class).to eq Table
  end

  describe 'Database table' do
    it { should have_db_column :contents }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :data_vector }
    it { should have_db_column :name }
    it { should have_db_column :team_id }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_one :step_table }
    it { should have_one :step }
    it { should have_one :result_table }
    it { should have_one :result }
    it { should have_many :report_elements }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :contents }
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end
    it do
      should validate_length_of(:contents)
               .is_at_most(Constants::TABLE_JSON_MAX_SIZE_MB.megabytes)
    end
  end
end
