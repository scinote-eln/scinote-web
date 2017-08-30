require 'rails_helper'

describe RepositoryTextValue, type: :model do
  it 'should be of class RepositoryTextValue' do
    expect(subject.class).to eq RepositoryTextValue
  end

  describe 'Database table' do
    it { should have_db_column :data }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_one :repository_cell }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :repository_cell }
    it { should validate_presence_of :data }
    it do
      should validate_length_of(:data).is_at_most(Constants::TEXT_MAX_LENGTH)
    end
  end
end
