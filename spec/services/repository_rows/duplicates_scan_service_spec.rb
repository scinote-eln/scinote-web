# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRows::DuplicatesScanService do
  let(:user) { create :user }
  let(:repository) { create :repository, created_by: user }
  let(:result) { described_class.new(repository).call }

  def create_row(name, archived: false)
    create :repository_row, repository: repository, name: name, created_by: user, last_modified_by: user,
                            archived: archived
  end

  def enforce_unique_names(case_sensitive: false)
    repository.update_columns(enforce_unique_item_names: true, unique_item_names_case_sensitive: case_sensitive)
  end

  describe 'Name column' do
    let!(:first) { create_row('Sample') }
    let!(:second) { create_row('  sample ') }
    let!(:third) { create_row('SAMPLE') }
    let!(:unique) { create_row('Other') }

    it 'finds nothing while uniqueness is not enforced' do
      expect(result).to be_empty
    end

    it 'matches names ignoring case and surrounding whitespace' do
      enforce_unique_names

      expect(result).to contain_exactly(first.id, second.id, third.id)
    end

    it 'matches names exactly (after trimming) when case sensitive' do
      exact = create_row('Sample ')
      enforce_unique_names(case_sensitive: true)

      expect(result).to contain_exactly(first.id, exact.id)
    end

    it 'ignores archived items' do
      enforce_unique_names
      second.update_columns(archived: true)
      third.update_columns(archived: true)

      expect(result).to be_empty
    end
  end

  describe 'Text columns' do
    let(:column) { create :repository_column, :text_type, repository: repository, created_by: user }
    let(:other_column) { create :repository_column, :text_type, repository: repository, created_by: user }
    let!(:first) { create_row('A') }
    let!(:second) { create_row('B') }
    let!(:third) { create_row('C') }

    before do
      RepositoryCell.create_with_value!(first, column, 'Lot 42', user)
      RepositoryCell.create_with_value!(second, column, 'lot 42 ', user)
      RepositoryCell.create_with_value!(third, column, 'Lot 43', user)
      RepositoryCell.create_with_value!(first, other_column, 'same', user)
      RepositoryCell.create_with_value!(third, other_column, 'same', user)
    end

    it 'only scans columns with enforced uniqueness' do
      column.update!(enforce_unique: true, unique_case_sensitive: false)

      expect(result).to contain_exactly(first.id, second.id)
    end

    it 'respects case sensitivity of the column' do
      column.update!(enforce_unique: true, unique_case_sensitive: true)

      expect(result).to be_empty
    end

    it 'lists an item duplicated in several columns once' do
      enforce_unique_names
      first.update_columns(name: 'B')
      column.update!(enforce_unique: true, unique_case_sensitive: false)
      other_column.update!(enforce_unique: true)

      expect(result).to contain_exactly(first.id, second.id, third.id)
    end
  end
end
