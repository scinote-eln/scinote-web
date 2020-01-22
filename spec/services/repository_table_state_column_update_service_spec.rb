# frozen_string_literal: true

require 'rails_helper'

describe RepositoryTableStateColumnUpdateService do
  let!(:team) { create :team }
  let!(:user_1) { create :user, email: 'user_one@asdf.com' }
  let!(:user_2) { create :user, email: 'user_two@asdf.com' }
  let!(:repository) do
    create :repository, name: 'my repo',
                        created_by: user_1,
                        team: team
  end
  let!(:repository_column_1) do
    create :repository_column, name: 'My column 1',
                               repository: repository,
                               data_type: :RepositoryTextValue
  end
  let!(:repository_column_2) do
    create :repository_column, name: 'My column 2',
                               repository: repository,
                               data_type: :RepositoryAssetValue
  end
  let!(:repository_row) do
    create :repository_row, name: 'A row',
                            repository: repository,
                            created_by: user_1,
                            last_modified_by: user_1
  end
  let!(:repository_row_two) do
    create :repository_row, name: 'B row',
                            repository: repository,
                            created_by: user_2,
                            last_modified_by: user_2
  end
  let!(:default_order) do
    [[2, 'asc']]
  end
  let!(:default_column_def) do
    { 'visible' => true,
      'searchable' => true,
      'search' => { 'search' => '',
                    'smart' => true,
                    'regex' => false,
                    'caseInsensitive' => true } }
  end
  let!(:service) do
    subject
  end

  describe '#update_states_with_new_column' do
    let!(:initial_state_1) do
      RepositoryTableStateService.new(user_1, repository).create_default_state
    end
    let!(:initial_state_2) do
      RepositoryTableStateService.new(user_2, repository).create_default_state
    end

    it 'should keep default repository states valid' do
      expect(initial_state_1).to be_valid_default_repository_table_state(2)
      expect(initial_state_2).to be_valid_default_repository_table_state(2)

      service.update_states_with_new_column(repository)
      service.update_states_with_new_column(repository)

      [user_1, user_2].each do |user|
        state = RepositoryTableStateService.new(user, repository).load_state
        expect(state).to be_valid_default_repository_table_state(4)
      end
    end

    it 'should calculate correct length' do
      expect(initial_state_1.state['length']).to eq 8
      expect(initial_state_2.state['length']).to eq 8

      service.update_states_with_new_column(repository)
      service.update_states_with_new_column(repository)

      [user_1, user_2].each do |user|
        state = RepositoryTableStateService.new(user, repository).load_state
        expect(state.state['length']).to eq 10
      end
    end

    it 'should keep order as it was' do
      initial_state_1.state['order'] = [[3, 'desc']]
      RepositoryTableStateService.new(user_1, repository).update_state(
        initial_state_1.state
      )
      initial_state_2.state['order'] = [[4, 'asc']]
      RepositoryTableStateService.new(user_2, repository).update_state(
        initial_state_2.state
      )

      service.update_states_with_new_column(repository)
      service.update_states_with_new_column(repository)

      state_1 = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state_1.state['order']).to eq([[3, 'desc']])
      state_2 = RepositoryTableStateService.new(user_2, repository).load_state
      expect(state_2.state['order']).to eq([[4, 'asc']])
    end

    it 'should keep search as it was' do
      search_1 = { 'search' => 'lala1', 'smart' => true, 'regex' => false,
                   'caseInsensitive' => true }
      initial_state_1.state['search'] = search_1
      RepositoryTableStateService.new(user_1, repository).update_state(
        initial_state_1.state
      )
      search_2 = { 'search' => 'lala1', 'smart' => true, 'regex' => false,
                   'caseInsensitive' => true }
      initial_state_2.state['search'] = search_2
      RepositoryTableStateService.new(user_2, repository).update_state(
        initial_state_2.state
      )

      service.update_states_with_new_column(repository)
      service.update_states_with_new_column(repository)

      state_1 = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state_1.state['search']).to eq search_1
      state_2 = RepositoryTableStateService.new(user_2, repository).load_state
      expect(state_2.state['search']).to eq search_2
    end

    it 'should keep columns as they were' do
      cols_1 = initial_state_1.state['columns'].deep_dup
      cols_2 = initial_state_2.state['columns'].deep_dup

      service.update_states_with_new_column(repository)
      service.update_states_with_new_column(repository)

      state_1 = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state_1.state['columns']).to eq(
        cols_1.push(default_column_def, default_column_def)
      )
      state_2 = RepositoryTableStateService.new(user_2, repository).load_state
      expect(state_2.state['columns']).to eq(
        cols_2.push(default_column_def, default_column_def)
      )
    end

    it 'should keep column order as it was' do
      initial_state_1.state['ColReorder'] = [5, 3, 2, 0, 1, 4, 6, 7]
      RepositoryTableStateService.new(user_1, repository).update_state(
        initial_state_1.state
      )
      initial_state_2.state['ColReorder'] = [0, 6, 1, 4, 5, 7, 2, 3]
      RepositoryTableStateService.new(user_2, repository).update_state(
        initial_state_2.state
      )

      service.update_states_with_new_column(repository)
      service.update_states_with_new_column(repository)

      state_1 = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state_1.state['ColReorder']).to eq([5, 3, 2, 0, 1, 4, 6, 7, 8, 9])
      state_2 = RepositoryTableStateService.new(user_2, repository).load_state
      expect(state_2.state['ColReorder']).to eq([0, 6, 1, 4, 5, 7, 2, 3, 8, 9])
    end
  end

  describe '#update_states_with_removed_column' do
    let!(:initial_state_1) do
      RepositoryTableStateService.new(user_1, repository).create_default_state
    end
    let!(:initial_state_2) do
      RepositoryTableStateService.new(user_2, repository).create_default_state
    end

    # For column removal, we often use the index '6' twice - first, to
    # remove 6th (out of 7) column, and afterwards, to remove the last,
    # 6th (out of 6) column

    it 'should keep default repository states valid' do
      expect(initial_state_1).to be_valid_default_repository_table_state(2)
      expect(initial_state_2).to be_valid_default_repository_table_state(2)

      service.update_states_with_removed_column(repository, 6)
      service.update_states_with_removed_column(repository, 6)

      [user_1, user_2].each do |user|
        state = RepositoryTableStateService.new(user, repository).load_state
        expect(state).to be_valid_default_repository_table_state(0)
      end
    end

    it 'should calculate correct length' do
      expect(initial_state_1.state['length']).to eq 8
      expect(initial_state_2.state['length']).to eq 8

      service.update_states_with_removed_column(repository, 6)
      service.update_states_with_removed_column(repository, 6)

      [user_1, user_2].each do |user|
        state = RepositoryTableStateService.new(user, repository).load_state
        expect(state.state['length']).to eq 6
      end
    end

    it 'should keep order as it was' do
      initial_state_1.state['order'] = [[3, 'desc']]
      RepositoryTableStateService.new(user_1, repository).update_state(
        initial_state_1.state
      )
      initial_state_2.state['order'] = [[7, 'asc']]
      RepositoryTableStateService.new(user_2, repository).update_state(
        initial_state_2.state
      )

      service.update_states_with_removed_column(repository, 6)
      service.update_states_with_removed_column(repository, 6)

      state_1 = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state_1.state['order']).to eq([[3, 'desc']])
      state_2 = RepositoryTableStateService.new(user_2, repository).load_state
      expect(state_2.state['order']).to eq(default_order)
    end

    it 'should keep search as it was' do
      search_1 = { 'search' => 'lala1', 'smart' => true, 'regex' => false,
                   'caseInsensitive' => true }
      initial_state_1.state['search'] = search_1
      RepositoryTableStateService.new(user_1, repository).update_state(
        initial_state_1.state
      )
      search_2 = { 'search' => 'lala1', 'smart' => true, 'regex' => false,
                   'caseInsensitive' => true }
      initial_state_2.state['search'] = search_2
      RepositoryTableStateService.new(user_2, repository).update_state(
        initial_state_2.state
      )

      service.update_states_with_removed_column(repository, 6)
      service.update_states_with_removed_column(repository, 6)

      state_1 = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state_1.state['search']).to eq search_1
      state_2 = RepositoryTableStateService.new(user_2, repository).load_state
      expect(state_2.state['search']).to eq search_2
    end

    it 'should keep columns as they were' do
      cols_1 = initial_state_1.state['columns'].deep_dup
      cols_1[4]['visible'] = false
      RepositoryTableStateService.new(user_1, repository).update_state(
        initial_state_1.state.merge('columns' => cols_1)
      )
      cols_1.delete_at(6)
      cols_1.delete_at(6)

      cols_2 = initial_state_2.state['columns'].deep_dup
      cols_2[4]['searchable'] = false
      RepositoryTableStateService.new(user_2, repository).update_state(
        initial_state_2.state.merge('columns' => cols_2)
      )
      cols_2.delete_at(6)
      cols_2.delete_at(6)

      service.update_states_with_removed_column(repository, 6)
      service.update_states_with_removed_column(repository, 6)

      state_1 = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state_1.state['columns']).to eq cols_1
      state_2 = RepositoryTableStateService.new(user_2, repository).load_state
      expect(state_2.state['columns']).to eq cols_2
    end

    it 'should keep column order as it was' do
      initial_state_1.state['ColReorder'] =
        [5, 3, 2, 0, 1, 4, 6, 7]
      RepositoryTableStateService.new(user_1, repository).update_state(
        initial_state_1.state
      )
      initial_state_2.state['ColReorder'] =
        [0, 6, 1, 4, 5, 7, 2, 3]
      RepositoryTableStateService.new(user_2, repository).update_state(
        initial_state_2.state
      )

      service.update_states_with_removed_column(repository, 6)
      service.update_states_with_removed_column(repository, 6)

      state_1 = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state_1.state['ColReorder']).to eq(
        [5, 3, 2, 0, 1, 4]
      )
      state_2 = RepositoryTableStateService.new(user_2, repository).load_state
      expect(state_2.state['ColReorder']).to eq(
        [0, 1, 4, 5, 2, 3]
      )
    end
  end

  describe 'consequential creations and removals' do
    let!(:repository_column_3) do
      create :repository_column, name: 'My column 3',
                                 repository: repository,
                                 data_type: :RepositoryTextValue
    end
    let!(:repository_column_4) do
      create :repository_column, name: 'My column 4',
                                 repository: repository,
                                 data_type: :RepositoryTextValue
    end
    let!(:initial_state) do
      state = RepositoryTableStateService.new(user_1, repository)
                                         .create_default_state
      state.state['order'] = [[8, 'desc']]
      (0..9).each do |idx|
        state.state['columns'][idx]['search']['search'] = "search_#{idx}"
      end
      state.state['ColReorder'] =
        [0, 1, 2, 9, 8, 4, 7, 3, 5, 6]
      RepositoryTableStateService.new(user_1, repository).update_state(
        state.state
      )
      state
    end

    it 'should update state accordingly' do
      expect(initial_state).to be_valid_repository_table_state(4)

      service.update_states_with_new_column(repository)

      state = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state).to be_valid_repository_table_state(5)
      expect(state.state['ColReorder']).to eq(
        [0, 1, 2, 9, 8, 4, 7, 3, 5, 6, 10]
      )

      service.update_states_with_removed_column(repository, 7)

      state = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state).to be_valid_repository_table_state(4)
      expect(state.state['ColReorder']).to eq(
        [0, 1, 2, 8, 7, 4, 3, 5, 6, 9]
      )
      expect(state.state['order']).to eq([[7, 'desc']])

      service.update_states_with_removed_column(repository, 7)

      state = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state).to be_valid_repository_table_state(3)
      expect(state.state['ColReorder']).to eq(
        [0, 1, 2, 7, 4, 3, 5, 6, 8]
      )
      expect(state.state['order']).to eq([[2, 'asc']])

      service.update_states_with_removed_column(repository, 7)

      state = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state).to be_valid_repository_table_state(2)
      expect(state.state['ColReorder']).to eq(
        [0, 1, 2, 4, 3, 5, 6, 7]
      )

      service.update_states_with_new_column(repository)
      service.update_states_with_new_column(repository)

      state = RepositoryTableStateService.new(user_1, repository).load_state
      expect(state).to be_valid_repository_table_state(4)
      expect(state.state['ColReorder']).to eq(
        [0, 1, 2, 4, 3, 5, 6, 7, 8, 9]
      )
    end
  end
end
