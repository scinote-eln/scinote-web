require 'rails_helper'

describe Report, type: :model do
  it 'should be of class Report' do
    expect(subject.class).to eq Report
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :description }
    it { should have_db_column :project_id }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to :project }
    it { should belong_to :user }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_many :report_elements }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :project }
    it { should validate_presence_of :user }
    it do
      should validate_length_of(:description)
              .is_at_most(Constants::TEXT_MAX_LENGTH)
    end
    it do
      should validate_length_of(:name)
              .is_at_least(Constants::NAME_MIN_LENGTH)
              .is_at_most(Constants::NAME_MAX_LENGTH)
    end
    it do
      should validate_uniqueness_of(:name)
               .scoped_to([:user, :project])
               .case_insensitive
    end
  end
end
