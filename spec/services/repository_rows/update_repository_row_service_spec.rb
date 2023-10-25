# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRows::UpdateRepositoryRowService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:row) { create :repository_row, repository: repository }
  let!(:column) { create :repository_column, :text_type, repository: repository }
  let(:service_call) do
    RepositoryRows::UpdateRepositoryRowService
      .call(repository_row: row, user: user, params: params)
  end

  context 'when service succeed' do
    context 'when repository cell does not exists' do
      let(:params) do
        {
          repository_cells: Hash[column.id, 'some value'],
          repository_row: {}
        }
      end

      it 'creates new cell' do
        expect { service_call }.to change(RepositoryCell, :count).by(1)
      end

      it 'returns true for record_updated' do
        expect(service_call.record_updated).to be_truthy
      end

      it 'returns true for succeeded' do
        expect(service_call.succeed?).to be_truthy
      end
    end

    context 'when repository cell needs to be deleted' do
      let(:params) do
        {
          repository_cells: Hash[column.id, ''],
          repository_row: {}
        }
      end

      before do
        RepositoryCell.create_with_value!(row, column, 'some data', user)
      end

      it 'deletes cell' do
        expect { service_call }.to change(RepositoryCell, :count).by(-1)
      end

      it 'returns true for record_updated' do
        expect(service_call.record_updated).to be_truthy
      end

      it 'returns true for succeed' do
        expect(service_call.succeed?).to be_truthy
      end
    end

    context 'when there is no repository_cells' do
      let(:params) do
        {
          repository_cells: {},
          repository_row: {}
        }
      end

      it 'returns false for record_updated' do
        expect(service_call.record_updated).to be_falsey
      end

      it 'returns true for succeeded' do
        expect(service_call.succeed?).to be_truthy
      end
    end

    context 'when has repository_row name param' do
      let(:params) do
        {
          repository_row: { name: 'new name' }
        }
      end

      it 'updates repository name' do
        expect { service_call }.to change(row, :name)
      end

      it 'returns true for record_updated' do
        expect(service_call.record_updated).to be_truthy
      end

      it 'returns true for succeed' do
        expect(service_call.succeed?).to be_truthy
      end
    end

    context 'when have cells for update' do
      let(:params) do
        {
          repository_cells: Hash[column.id, 'New value'],
          repository_row: {}
        }
      end

      it 'updates cell value data' do
        cell = RepositoryCell.create_with_value!(row, column, 'some data', user)

        expect { service_call }.to(change { cell.reload.value.data })
      end

      it 'returns true for succeed' do
        RepositoryCell.create_with_value!(row, column, 'some data', user)

        expect(service_call.succeed?).to be_truthy
      end
    end
  end

  context 'when service does succeed with empty repository name' do
    context 'when updates repository_row and cell' do
      let(:params) do
        {
          repository_cells: Hash[column.id, 'New value'],
          repository_row: { name: '' }
        }
      end

      it 'update cells, but not repository row name' do
        cell = RepositoryCell.create_with_value!(row, column, 'some data', user)

        expect { service_call }.to(change { cell.reload.value.data })
        expect { service_call }.not_to(change { row.reload.name })
      end
    end

    context 'when repository_row name update fails' do
      let(:params) do
        {
          repository_row: { name: '' }
        }
      end

      it 'returns true for succeed' do
        expect(service_call.succeed?).to be_truthy
        expect { service_call }.not_to(change { row.reload.name })
        expect(service_call.errors.count).to eq(0)
      end
    end
  end
end
