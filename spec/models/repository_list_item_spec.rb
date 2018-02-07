require 'rails_helper'

RSpec.describe RepositoryListItem, type: :model do
  it 'should be of class RepositoryListItem' do
    expect(subject.class).to eq RepositoryListItem
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :repository_list_value_id }
  end

  describe 'Relations' do
    it { should belong_to(:repository_list_value) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:name) }
    it do
      should validate_length_of(:name).is_at_most(Constants::TEXT_MAX_LENGTH)
    end
  end
end
