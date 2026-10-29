# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumnsHelper, type: :helper do
  let(:user) { create :user }
  let(:repository) { create :repository, created_by: user, team: create(:team, created_by: user) }
  let!(:columns) { create_list :repository_column, 3, repository: repository, created_by: user }

  before do
    without_partial_double_verification { allow(helper).to receive(:current_user).and_return(user) }
  end

  describe '#defined_delimiters_options' do
    it 'maps the translated delimiter names to their keys, with auto first' do
      options = helper.defined_delimiters_options

      expect(options.keys.first).to eq I18n.t('libraries.manange_modal_column.list_type.delimiters.auto')
      expect(options.values).to eq [:auto, *Constants::REPOSITORY_LIST_ITEMS_DELIMITERS_MAP.keys]
    end
  end

  describe '#repository_columns_ordered_by_state' do
    let(:repository_row) { create :repository_row, repository: repository, created_by: user }

    def save_state(view_mode, columns_state)
      user.user_settings.create!(
        key: "repository_table_#{repository.id}_#{view_mode}_table_state",
        value: { 'columnsState' => columns_state }
      )
    end

    it 'returns an empty list for a repository without columns' do
      empty_repository = create :repository, created_by: user, team: repository.team
      empty_row = create :repository_row, repository: empty_repository, created_by: user

      expect(helper.repository_columns_ordered_by_state(empty_row)).to eq []
    end

    it 'returns columns by id when the user has no table state' do
      expect(helper.repository_columns_ordered_by_state(repository_row)).to eq columns
    end

    it 'returns columns by id when the saved state has no columnsState' do
      save_state('active', nil)

      expect(helper.repository_columns_ordered_by_state(repository_row)).to eq columns
    end

    it 'orders columns by their saved colId position' do
      save_state('active', [{ 'colId' => "col_#{columns[2].id}" }, { 'colId' => "col_#{columns[0].id}" }])

      expect(helper.repository_columns_ordered_by_state(repository_row)).to eq [columns[2], columns[0], columns[1]]
    end

    it 'keeps columns missing from the saved state at the end' do
      save_state('active', [{ 'colId' => "col_#{columns[1].id}" }])

      expect(helper.repository_columns_ordered_by_state(repository_row)).to eq [columns[1], columns[0], columns[2]]
    end

    it 'ignores saved colIds that are not custom columns' do
      save_state('active', [{ 'colId' => 'checkbox' }, { 'colId' => "col_#{columns[2].id}" }, { 'colId' => 'name' }])

      expect(helper.repository_columns_ordered_by_state(repository_row)).to eq [columns[2], columns[0], columns[1]]
    end

    it 'ignores saved colIds that point to a column that no longer exists' do
      save_state('active', [{ 'colId' => "col_#{columns[2].id}" }, { 'colId' => 'col_999999' }])

      expect(helper.repository_columns_ordered_by_state(repository_row)).to eq [columns[2], columns[0], columns[1]]
    end

    it 'maps the stock colId to the stock-type column' do
      stock_column = create :repository_column, :stock_type, repository: repository, created_by: user

      save_state('active', [{ 'colId' => 'stock' }])

      expect(helper.repository_columns_ordered_by_state(repository_row))
        .to eq [stock_column, columns[0], columns[1], columns[2]]
    end

    it 'uses the archived view state for an archived row' do
      archived_row = create :repository_row, :archived, repository: repository, created_by: user
      save_state('active', [{ 'colId' => "col_#{columns[2].id}" }])
      save_state('archived', [{ 'colId' => "col_#{columns[1].id}" }])

      expect(helper.repository_columns_ordered_by_state(archived_row)).to eq [columns[1], columns[0], columns[2]]
    end
  end
end
