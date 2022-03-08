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

  describe 'data_different?' do
    context 'when has new data' do
      it do
        expect(repository_list_value.data_different?('-1')).to be_truthy
      end
    end

    context 'when has same data' do
      it do
        repository_list_value.save
        id = repository_list_value.repository_list_item.id

        expect(repository_list_value.data_different?(id)).to be_falsey
      end
    end
  end

  describe 'update_data!' do
    let(:user) { create :user }
    let(:new_list_item) do
      create :repository_list_item, repository_column: repository_list_value.repository_list_item.repository_column
    end
    context 'when update data' do
      it 'should change last_modified_by and data' do
        repository_list_value.save

        expect { repository_list_value.update_data!(new_list_item.id, user) }
          .to(change { repository_list_value.reload.last_modified_by.id }
                .and(change { repository_list_value.reload.data }))
      end
    end
  end

  describe 'self.new_with_payload' do
    let(:user) { create :user }
    let(:column) { create :repository_column }
    let(:list_item) { create :repository_list_item, repository_column: column }
    let(:cell) { build :repository_cell, repository_column: column }
    let(:attributes) do
      {
        repository_cell: cell,
        created_by: user,
        last_modified_by: user
      }
    end

    it do
      expect(RepositoryListValue.new_with_payload(list_item.id, attributes))
        .to be_an_instance_of RepositoryListValue
    end
  end
end
