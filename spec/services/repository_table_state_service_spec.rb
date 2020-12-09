# frozen_string_literal: true

require 'rails_helper'

describe RepositoryTableStateService do
  let!(:team) { create :team }
  let!(:user) { create :user, email: 'user_one@asdf.com' }
  let!(:repository) do
    create :repository, name: 'my repo',
                        created_by: user,
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
                            created_by: user,
                            last_modified_by: user
  end
  let!(:repository_row_two) do
    create :repository_row, name: 'B row',
                            repository: repository,
                            created_by: user,
                            last_modified_by: user
  end
  let!(:service) do
    RepositoryTableStateService.new(user, repository)
  end

  describe '#create_default_state' do
    let!(:initial_state) do
      RepositoryTableStateService.new(user, repository).create_default_state
    end

    context('record counts') do
      let!(:query) do
        RepositoryTableState.where(user: user, repository: repository)
      end

      it 'deletes old entry and creates new entry that is returned' do
        expect(query.count).to eq 1

        new_state = service.create_default_state

        expect(query.reload.count).to eq 1
        expect(query.take).to eq new_state
      end

      it 'always keeps one object per user-repository combination' do
        expect(query.count).to eq 1

        5.times { service.create_default_state }

        expect(query.reload.count).to eq 1
      end
    end

    it 'should have valid structure' do
      record = service.create_default_state

      expect(record).to be_valid_default_repository_table_state(2)
    end
  end

  describe '#load_state' do
    it 'should load initial state if it exists' do
      initial_state = RepositoryTableStateService.new(user, repository).create_default_state
      record = service.load_state
      expect(record).to eq initial_state
    end

    it 'should load/create default state if it does not exist' do
      RepositoryTableState.where(user: user, repository: repository).destroy_all

      record = service.load_state
      expect(record).to be_valid_default_repository_table_state(2)
    end
  end

  describe '#update_state' do
    let!(:new_state) do
      initial_state = RepositoryTableStateService.new(user, repository).create_default_state
      initial_state.state['columns'][3]['visible'] = false
      initial_state.state
    end

    it 'should update the state' do
      service.update_state(new_state)

      record =
        RepositoryTableState.where(user: user, repository: repository).take

      expect(record).to be_truthy
      expect(record.state).to eq new_state
    end
  end
end
