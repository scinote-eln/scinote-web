require 'rails_helper'

RSpec.describe RepositoryListItem, type: :model do
  it 'should be of class RepositoryListItem' do
    expect(subject.class).to eq RepositoryListItem
  end

  describe 'Database table' do
    it { should have_db_column :data }
    it { should have_db_column :repository_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :repository_column_id }
  end

  describe 'Relations' do
    it { should have_many :repository_list_values }
    it { should belong_to :repository }
    it { should belong_to :repository_column }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
  end

  describe 'Validations' do
    let!(:user) { create :user }
    let!(:repository_one) { create :repository }
    it { should validate_presence_of(:data) }
    it do
      should validate_length_of(:data).is_at_most(Constants::TEXT_MAX_LENGTH)
    end

    context 'has a uniq data scoped on repository column' do
      let!(:repository_column) do
        create :repository_column, name: 'My column', repository: repository_one
      end
      let!(:repository_two) { create :repository, name: 'New repo' }
      let!(:repository_column_two) do
        create :repository_column, name: 'My column', repository: repository_two
      end
      let!(:repository_list_item) do
        create :repository_list_item,
               data: 'Test',
               repository: repository_one,
               repository_column: repository_column
      end

      it 'creates a repository list item in same repository' do
        new_item = build :repository_list_item,
                         data: 'Test',
                         repository: repository_one,
                         repository_column: repository_column
        expect(new_item).to_not be_valid
        expect(
          new_item.errors.full_messages.first
        ).to eq 'Data has already been taken'
      end

      it 'create a repository list item in other repository' do
        new_item = build :repository_list_item,
                         data: 'Test',
                         repository: repository_two,
                         repository_column: repository_column_two
        expect(new_item).to be_valid
      end
    end
  end
end
