# frozen_string_literal: true

require 'rails_helper'

describe RepositoryStatusValue do
  let(:repository_status_value) { build :repository_status_value }

  it 'is valid' do
    expect(repository_status_value).to be_valid
  end

  describe 'Validations' do
    describe '#repository_status_item' do
      it { is_expected.to validate_presence_of(:repository_status_item) }
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:repository_status_item) }
    it { is_expected.to belong_to(:created_by).optional }
    it { is_expected.to belong_to(:last_modified_by).optional }
  end

  describe '.data_different?' do
    context 'when has new data' do
      it do
        expect(repository_status_value.data_different?('-1')).to be_truthy
      end
    end

    context 'when has same data' do
      it do
        repository_status_value.save
        id = repository_status_value.repository_status_item.id

        expect(repository_status_value.data_different?(id)).to be_falsey
      end
    end
  end

  describe '.update_data!' do
    let(:user) { create :user }
    let(:new_status_item) do
      create :repository_status_item,
             repository_column: repository_status_value.repository_status_item.repository_column
    end

    context 'when update data' do
      it 'should change last_modified_by and data' do
        repository_status_value.save

        expect { repository_status_value.update_data!(new_status_item.id, user) }
          .to(change { repository_status_value.reload.last_modified_by.id }
                .and(change { repository_status_value.reload.data }))
      end
    end
  end

  describe 'self.new_with_payload' do
    let(:user) { create :user }
    let(:column) { create :repository_column }
    let(:cell) { build :repository_cell, repository_column: column }
    let(:list_item) { create :repository_status_item, repository_column: column }
    let(:attributes) do
      {
        repository_cell: cell,
        created_by: user,
        last_modified_by: user
      }
    end

    it do
      expect(RepositoryStatusValue.new_with_payload(list_item.id, attributes))
        .to be_an_instance_of RepositoryStatusValue
    end
  end
end
