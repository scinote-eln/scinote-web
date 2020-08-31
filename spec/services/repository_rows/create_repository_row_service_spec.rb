# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRows::CreateRepositoryRowService do
  let(:user) { create :user }
  let(:repository) { create :repository }
  let!(:column) { create :repository_column, :text_type, repository: repository }
  let!(:date_column) { create :repository_column, :date_type, repository: repository }
  let(:service_call) do
    RepositoryRows::CreateRepositoryRowService
      .call(repository: repository, user: user, params: params)
  end

  context 'when service succeed' do
    let(:params) do
      {
        repository_cells: Hash[column.id, 'some value'],
        repository_row: {
          name: 'repo name'
        }
      }
    end

    it 'creates new row' do
      expect { service_call }.to change(RepositoryRow, :count).by(1)
    end

    it 'creates new cell' do
      expect { service_call }.to change(RepositoryCell, :count).by(1)
    end

    it 'returns true for succeeded' do
      expect(service_call.succeed?).to be_truthy
    end
  end

  context 'when service does not succeed' do
    context 'when repository_row is valid but cell is not' do
      let(:params) do
        {
          repository_cells: Hash[column.id, ''],
          repository_row: { name: '' }
        }
      end

      it 'reverts repository_row creation' do
        expect { service_call }.not_to(change(RepositoryRow, :count))
      end
    end
  end
end
