# frozen_string_literal: true

require 'rails_helper'

describe RepositoryTextValue, type: :model do
  let(:repository_text_value) { build :repository_text_value }

  it 'is valid' do
    expect(repository_text_value).to be_valid
  end

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

  describe 'Validations' do
    it { should validate_presence_of :repository_cell }
    it { should validate_presence_of :data }
    it do
      should validate_length_of(:data).is_at_most(Constants::TEXT_MAX_LENGTH)
    end
  end

  describe 'data_changed?' do
    context 'when has new data' do
      it do
        expect(repository_text_value.data_changed?('newData')).to be_truthy
      end
    end

    context 'when has same data' do
      it do
        data = repository_text_value.data
        expect(repository_text_value.data_changed?(data)).to be_falsey
      end
    end
  end

  describe 'update_data!' do
    let(:user) { create :user }

    context 'when update data' do
      it 'should change last_modified_by and data' do
        repository_text_value.save

        expect { repository_text_value.update_data!('newData', user) }
          .to(change { repository_text_value.reload.last_modified_by.id }
                .and(change { repository_text_value.reload.data }))
      end
    end
  end

  describe 'self.new_with_payload' do
    let(:user) { create :user }
    let(:column) { create :repository_column }
    let(:cell) { build :repository_cell, repository_column: column }
    let(:attributes) do
      {
        repository_cell: cell,
        created_by: user,
        last_modified_by: user
      }
    end
    it do
      expect(RepositoryTextValue.new_with_payload('some data', attributes))
        .to be_an_instance_of RepositoryTextValue
    end
  end
end
