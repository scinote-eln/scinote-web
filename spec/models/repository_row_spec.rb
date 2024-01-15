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
    it { should have_db_column :parent_connections_count }
    it { should have_db_column :child_connections_count }
  end

  describe 'Relations' do
    it { should belong_to(:repository) }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_many :repository_cells }
    it { should have_many :repository_columns }
    it { should have_many :my_module_repository_rows }
    it { should have_many :my_modules }
    it { should have_many(:child_connections).class_name('RepositoryRowConnection').with_foreign_key('parent_id').dependent(:destroy).inverse_of(:parent) }
    it { should have_many(:child_repository_rows).through(:child_connections).source(:child) }
    it { should have_many(:parent_connections).class_name('RepositoryRowConnection').with_foreign_key('child_id').dependent(:destroy).inverse_of(:child) }
    it { should have_many(:parent_repository_rows).through(:parent_connections).source(:parent) }
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

  describe '.relationship_count' do
    context 'when first created' do
      let(:repository_row) { create :repository_row }
      it 'returns zero' do
        expect(repository_row.relationship_count).to be_zero
      end
    end

    context 'when it has only parents' do
      let(:nbr_of_parents) { 3 }
      let(:repository_row) { create :repository_row, :with_parents, nbr_of_parents: nbr_of_parents }

      it 'returns the number of parents' do
        expect(repository_row.relationship_count).to be_eql(nbr_of_parents)
      end
    end

    context 'when it has only children' do
      let(:nbr_of_children) { 4 }
      let(:repository_row) { create :repository_row, :with_children, nbr_of_children: nbr_of_children }

      it 'returns the number of children' do
        expect(repository_row.relationship_count).to be_eql(nbr_of_children)
      end
    end

    context 'when it has both children and parents' do
      let(:nbr_of_children) { 4 }
      let(:nbr_of_parents) { 5 }
      let(:repository_row) { create :repository_row,
                                    :with_children,
                                    :with_parents,
                                    nbr_of_parents: nbr_of_parents,
                                    nbr_of_children: nbr_of_children }

      it 'returns the total sum of children and parents' do
        expect(repository_row.relationship_count).to be_eql(nbr_of_children + nbr_of_parents)
      end
    end
  end
end
