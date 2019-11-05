# frozen_string_literal: true

require 'rails_helper'

describe RepositoryActions::DuplicateRows do
  let!(:user) { create :user }
  let!(:repository) { create :repository }
  let!(:list_column) do
    create(:repository_column, name: 'list',
                               repository: repository,
                               created_by: user,
                               data_type: 'RepositoryListValue')
  end
  let!(:text_column) do
    create(:repository_column, name: 'text',
                               repository: repository,
                               created_by: user,
                               data_type: 'RepositoryTextValue')
  end

  describe '#call' do
    before do
      @rows_ids = []

      3.times do |index|
        row = create :repository_row, name: "row (#{index})",
                                      repository: repository
        create :repository_text_value, data: "text (#{index})",
                                       repository_cell_attributes: {
                                         repository_row: row,
                                         repository_column: text_column
                                       }
        create :repository_list_value,
               repository_list_item: create(:repository_list_item,
                                            repository: repository,
                                            repository_column: list_column,
                                            data: "list item (#{index})"),
               repository_cell_attributes: {
                 repository_row: row,
                 repository_column: list_column
               }
        @rows_ids << row.id.to_s
      end
    end

    it 'generates a duplicate of selected items' do
      expect(repository.repository_rows.reload.size).to eq 3
      described_class.new(user, repository, @rows_ids).call
      expect(repository.repository_rows.reload.size).to eq 6
    end

    it 'generates an exact duplicate of the row with custom column values' do
      described_class.new(user, repository, [@rows_ids.first]).call
      duplicated_row = repository.repository_rows.order('created_at ASC').last
      expect(duplicated_row.name).to eq 'row (0) (1)'
      duplicated_row.repository_cells.each do |cell|
        if cell.value_type == 'RepositoryListValue'
          expect(cell.value.data).to eq 'list item (0)'
        else
          expect(cell.value.data).to eq 'text (0)'
        end
      end
    end

    it 'prevents to duplicate items that do not already belong to repository' do
      new_repository = create :repository, name: 'new repo'
      new_row = create :repository_row, name: 'other row',
                                        repository: new_repository
      described_class.new(user, repository, [new_row.id]).call
      expect(repository.repository_rows.reload.size).to eq 3
    end

    it 'returns the number of duplicated items' do
      service_obj = described_class.new(user, repository, @rows_ids)
      service_obj.call
      expect(service_obj.number_of_duplicated_items).to eq 3
    end

    it 'returns the number of duplicated items' do
      service_obj = described_class.new(user, repository, [])
      service_obj.call
      expect(service_obj.number_of_duplicated_items).to eq 0
    end

    it 'calls create activity for copying intentory items 3 times' do
      expect(Activities::CreateActivityService)
        .to(receive(:call).with(hash_including(activity_type: :copy_inventory_item))).exactly(3).times

      described_class.new(user, repository, @rows_ids).call
    end

    it 'adds 3 activities in DB' do
      expect { described_class.new(user, repository, @rows_ids).call }
        .to(change { Activity.count }.by(3))
    end
  end
end
