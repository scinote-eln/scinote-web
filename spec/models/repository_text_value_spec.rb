# frozen_string_literal: true

require 'rails_helper'

describe RepositoryTextValue, type: :model do
  let(:repository_text_value) { create :repository_text_value }

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

    describe 'unique entries' do
      let(:user) { create :user }
      let(:repository) { create :repository, created_by: user }
      let(:column) { create :repository_column, :text_type, repository: repository, created_by: user, enforce_unique: true }
      let(:row) { create :repository_row, repository: repository, created_by: user }
      let(:other_row) { create :repository_row, repository: repository, created_by: user }
      let!(:existing_cell) { RepositoryCell.create_with_value!(row, column, 'Lot 42', user) }

      def build_value(data, repository_row = other_row, repository_column = column)
        RepositoryTextValue.new_with_payload(
          data,
          repository_cell: RepositoryCell.new(repository_row: repository_row, repository_column: repository_column),
          created_by: user, last_modified_by: user
        )
      end

      it 'rejects a duplicate value ignoring surrounding whitespace' do
        value = build_value("  Lot 42\n")

        expect(value).not_to be_valid
        expect(value.not_unique_error?).to be true
        expect(value.errors.messages_for(:data)).to include('An item with this value already exists')
      end

      it 'is case sensitive by default' do
        expect(column.unique_case_sensitive?).to be true
        expect(build_value('lot 42')).to be_valid
      end

      context 'when case insensitive' do
        before { column.update!(unique_case_sensitive: false) }

        it 'rejects a value differing only in case' do
          expect(build_value('LOT 42')).not_to be_valid
        end
      end

      it 'counts values of archived items' do
        row.update!(archived: true, archived_on: Time.zone.now, archived_by: user)

        expect(build_value('Lot 42')).not_to be_valid
      end

      it 'allows a different value' do
        expect(build_value('Lot 43')).to be_valid
      end

      it 'allows the same value in another column' do
        other_column = create :repository_column, :text_type, repository: repository, created_by: user,
                                                              enforce_unique: true

        expect(build_value('Lot 42', other_row, other_column)).to be_valid
      end

      it 'does not apply when the column does not enforce unique entries' do
        column.update!(enforce_unique: false)

        expect(build_value('Lot 42')).to be_valid
      end

      it 'does not apply when inventory integrity is disabled' do
        allow(RepositoryBase).to receive(:inventory_integrity_enabled?).and_return(false)

        expect(build_value('Lot 42')).to be_valid
      end

      it 'does not block saving an existing value that did not change' do
        column.update!(enforce_unique: false)
        duplicate_cell = RepositoryCell.create_with_value!(other_row, column, 'Lot 42', user)
        column.update!(enforce_unique: true)

        duplicate_value = duplicate_cell.value.reload
        duplicate_value.last_modified_by = user
        expect(duplicate_value).to be_valid
      end
    end
  end

  describe 'data_different?' do
    context 'when has new data' do
      it do
        expect(repository_text_value.data_different?('newData')).to be_truthy
      end
    end

    context 'when has same data' do
      it do
        data = repository_text_value.data
        expect(repository_text_value.data_different?(data)).to be_falsey
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
