# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumnsHelper, type: :helper do
  let(:user) { create :user }
  let(:repository) { create :repository, created_by: user, team: create(:team, created_by: user) }
  let!(:columns) { create_list :repository_column, 3, repository: repository, created_by: user }
  let(:default_order) { repository.default_table_state['ColReorder'] }
  let(:default_count) { default_order.length }

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
    def save_state(col_reorder)
      create :repository_table_state, user: user, repository: repository,
                                      state: { 'ColReorder' => col_reorder }
    end

    it 'returns an empty list for a repository without columns' do
      empty = create :repository, created_by: user, team: repository.team

      expect(helper.repository_columns_ordered_by_state(empty)).to eq []
    end

    it 'returns columns by id when the user has no table state' do
      expect(helper.repository_columns_ordered_by_state(repository)).to eq columns
    end

    it 'returns columns by id when the state has no column reordering' do
      create :repository_table_state, user: user, repository: repository, state: {}

      expect(helper.repository_columns_ordered_by_state(repository)).to eq columns
    end

    it 'returns columns by id when only default positions are present' do
      save_state(default_order)

      expect(helper.repository_columns_ordered_by_state(repository)).to eq columns
    end

    it 'orders custom columns by their saved position' do
      save_state(default_order + [default_count + 2, default_count, default_count + 1])

      expect(helper.repository_columns_ordered_by_state(repository)).to eq [columns[2], columns[0], columns[1]]
    end

    it 'keeps columns missing from the saved state at the end' do
      save_state(default_order + [default_count + 1])

      expect(helper.repository_columns_ordered_by_state(repository)).to eq [columns[1], columns[0], columns[2]]
    end

    it 'ignores saved positions that point to no column' do
      save_state(default_order + [default_count + 10, default_count + 2])

      expect(helper.repository_columns_ordered_by_state(repository)).to eq [columns[2], columns[0], columns[1]]
    end
  end
end
