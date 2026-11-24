# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRows::DuplicateValidationService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let!(:text_column) { create :repository_column, :text_type, repository: repository, created_by: user }
  let!(:row_one) { create :repository_row, name: 'Sample', repository: repository, created_by: user }
  let!(:row_two) { create :repository_row, name: 'Other', repository: repository, created_by: user }
  let(:service) { described_class.new(repository, [row_one, row_two]) }

  it 'passes when nothing is mandatory or unique' do
    expect(service.error).to be_nil
  end

  context 'with a mandatory column' do
    before { text_column.update!(mandatory: true) }

    it 'fails when one of the items has the mandatory column empty' do
      RepositoryCell.create_with_value!(row_one, text_column, 'filled', user)

      expect(service.error).to eq(:mandatory)
    end

    it 'passes when all items have the mandatory column filled' do
      RepositoryCell.create_with_value!(row_one, text_column, 'filled', user)
      RepositoryCell.create_with_value!(row_two, text_column, 'filled too', user)

      expect(service.error).to be_nil
    end

    it 'reports the mandatory failure before a unique one' do
      text_column.update!(enforce_unique: true)
      RepositoryCell.create_with_value!(row_one, text_column, 'filled', user)

      expect(service.error).to eq(:mandatory)
    end
  end

  context 'with a unique text column' do
    before { text_column.update!(enforce_unique: true) }

    it 'fails when an item has a value in it' do
      RepositoryCell.create_with_value!(row_two, text_column, 'Lot 42', user)

      expect(service.error).to eq(:unique)
    end

    it 'passes when the selected items have no value in it' do
      expect(service.error).to be_nil
    end

    it 'reports the column of a single item' do
      RepositoryCell.create_with_value!(row_one, text_column, 'Lot 42', user)

      expect(described_class.new(repository, [row_one]).unique_errors)
        .to eq(unique_cells: { text_column.id => ['An item with this value already exists'] })
    end
  end

  context 'with unique item names' do
    before { repository.update!(enforce_unique_item_names: true) }

    it 'passes when the duplicate names are free' do
      expect(service.error).to be_nil
    end

    it 'fails when a duplicate name is taken, ignoring case' do
      create :repository_row, name: 'sample (1)', repository: repository, created_by: user

      expect(service.error).to eq(:unique)
      expect(described_class.new(repository, [row_one]).unique_errors)
        .to eq(name: ['An item with this name already exists'])
    end

    it 'does not check names when the repository does not enforce them' do
      repository.update!(enforce_unique_item_names: false)
      create :repository_row, name: 'Sample (1)', repository: repository, created_by: user

      expect(service.error).to be_nil
    end
  end
end
