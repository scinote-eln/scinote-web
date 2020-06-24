# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRow, type: :model do
  let(:repository_row) { build :repository_row }

  it 'is valid' do
    expect(repository_row).to be_valid
  end

  it 'should be of class RepositoryRow' do
    expect(subject.class).to eq RepositoryRow
  end

  describe 'Database table' do
    it { should have_db_column :repository_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :name }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:repository) }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_many :repository_cells }
    it { should have_many :repository_columns }
    it { should have_many :my_module_repository_rows }
    it { should have_many :my_modules }
  end

  describe 'Validations' do
    describe '#name' do
      it { is_expected.to validate_presence_of :name }
      it { is_expected.to(validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)) }
    end

    describe '#created_by' do
      it { is_expected.to validate_presence_of :created_by }
    end
  end

  describe '.archived' do
    context 'when archived' do
      let(:repository_row) { build :repository_row, :archived }
      it 'returns true' do
        expect(repository_row.archived).to be_truthy
      end
    end

    context 'when not archived' do
      context 'when parent not archived' do
        let(:repository_row) { build :repository_row }

        it 'returns false' do
          expect(repository_row.archived).to be_falsey
        end
      end

      context 'when parent archived' do
        let(:repository_row) { build :repository_row, repository: archived_repository }
        let(:archived_repository) { create :repository, :archived }

        it 'returns true' do
          expect(repository_row.archived).to be_truthy
        end
      end
    end
  end

  describe '.archived?' do
    context 'when archived' do
      let(:repository_row) { build :repository_row, :archived }
      it 'returns true' do
        expect(repository_row.archived?).to be_truthy
      end
    end

    context 'when not archived' do
      context 'when parent not archived' do
        let(:repository_row) { build :repository_row }

        it 'returns false' do
          expect(repository_row.archived?).to be_falsey
        end
      end

      context 'when parent archived' do
        let(:repository_row) { build :repository_row, repository: archived_repository }
        let(:archived_repository) { create :repository, :archived }

        it 'returns true' do
          expect(repository_row.archived?).to be_truthy
        end
      end
    end
  end

  describe '.archived_by' do
    context 'when archived' do
      let(:repository_row) { build :repository_row, :archived }
      it 'returns user' do
        expect(repository_row.archived_by).to be_instance_of User
      end
    end

    context 'when not archived' do
      context 'when parent not archived' do
        let(:repository_row) { build :repository_row }

        it 'returns nil' do
          expect(repository_row.archived_by).to be_nil
        end
      end

      context 'when parent archived' do
        let(:repository_row) { build :repository_row, repository: archived_repository }
        let(:archived_repository) { create :repository, :archived }

        it 'returns repository archived_by user' do
          expect(repository_row.archived_by).to be_eql(archived_repository.archived_by)
        end
      end
    end
  end

  describe '.archived_on' do
    context 'when archived' do
      let(:repository_row) { build :repository_row, :archived }
      it 'returns time' do
        expect(repository_row.archived_on).not_to be_nil
      end
    end

    context 'when not archived' do
      context 'when parent not archived' do
        let(:repository_row) { build :repository_row }

        it 'returns nil' do
          expect(repository_row.archived_on).to be_nil
        end
      end

      context 'when parent archived' do
        let(:repository_row) { create :repository_row, repository: archived_repository }
        let(:archived_repository) { create :repository, :archived }

        it 'returns times of archiving parent' do
          expect(repository_row.archived_on).to be_eql(archived_repository.archived_on)
        end
      end
    end
  end
end
