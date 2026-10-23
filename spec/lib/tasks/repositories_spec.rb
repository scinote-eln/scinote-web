# frozen_string_literal: true

require 'rails_helper'

describe 'repositories:remove_rows_and_columns_without_repository' do
  include_context 'rake file loaded once', 'repositories'

  let(:repository) { create :repository }
  let(:missing_repository_id) { RepositoryBase.maximum(:id).to_i + 100_000 }

  let!(:kept_row) { create :repository_row, repository: repository }
  let!(:kept_column) { create :repository_column, repository: repository }
  let!(:orphan_row) do
    create(:repository_row, repository: create(:repository)).tap { |r| r.update_column(:repository_id, missing_repository_id) }
  end
  let!(:orphan_column) do
    create(:repository_column, repository: create(:repository)).tap { |c| c.update_column(:repository_id, missing_repository_id) }
  end

  it 'destroys rows and columns whose repository does not exist' do
    pending 'bug: the task skips the :update_repository_table_states_with_removed_column callback, which no longer exists, and raises ArgumentError'
    rake_task('repositories:remove_rows_and_columns_without_repository').invoke

    expect(RepositoryRow.exists?(orphan_row.id)).to be(false)
    expect(RepositoryColumn.exists?(orphan_column.id)).to be(false)
  end

  it 'keeps rows and columns of existing repositories' do
    pending 'bug: the task skips the :update_repository_table_states_with_removed_column callback, which no longer exists, and raises ArgumentError'
    rake_task('repositories:remove_rows_and_columns_without_repository').invoke

    expect(RepositoryRow.exists?(kept_row.id)).to be(true)
    expect(RepositoryColumn.exists?(kept_column.id)).to be(true)
  end
end

describe 'repositories:set_name_column_visibility' do
  include_context 'rake file loaded once', 'repositories'

  let(:repository) { create :repository }

  def state_for(state)
    create :repository_table_state, repository: repository, state: state
  end

  it 'sets the Name column (id 3) visibility to true' do
    hidden = state_for('columns' => { '3' => { 'visible' => 'false', 'x' => 1 }, '4' => { 'visible' => 'false' } })

    rake_task('repositories:set_name_column_visibility').invoke

    columns = hidden.reload.state['columns']
    expect(columns['3']).to include('visible' => 'true', 'x' => 1)
    expect(columns['4']['visible']).to eq('false')
  end

  it 'skips states that have no Name column entry' do
    other = state_for('columns' => { '4' => { 'visible' => 'false' } })

    expect { rake_task('repositories:set_name_column_visibility').invoke }
      .not_to(change { other.reload.state })
  end
end
