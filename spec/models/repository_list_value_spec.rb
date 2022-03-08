# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepositoryListValue, type: :model do
  let(:repository_list_value) { build :repository_list_value }

  it 'is valid' do
    expect(repository_list_value).to be_valid
  end

  it 'should be of class RepositoryListValue' do
    expect(subject.class).to eq RepositoryListValue
  end

  describe 'Database table' do
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :repository_list_item_id }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should belong_to(:repository_list_item) }
    it { should accept_nested_attributes_for(:repository_cell) }
  end

  describe '#formatted' do
    let(:list_item) { create :repository_list_item, data: 'my item' }

    it 'returns the formatted data of a selected item' do
      repository_list_value = create :repository_list_value, repository_list_item: list_item

      expect(repository_list_value.reload.formatted).to eq 'my item'
    end
  end

  describe '#data' do
    let(:list_item) { create :repository_list_item, data: 'my item' }
    let(:repository_list_value) { create :repository_list_value, repository_list_item: list_item }

    it 'returns the data of a selected item' do
      expect(repository_list_value.reload.data).to eq 'my item'
    end

    # Not sure if this test make sense, because validation will fail before hit this function. Updated in SCI-3183
    it 'retuns only the item related to the list' do
      repository_list_value.repository_list_item = nil
      repository_list_value.save(validate: false)

      expect(repository_list_value.reload.data).to be_nil
    end
  end
end
