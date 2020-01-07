# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumns::DeleteColumnService do
  let(:user) { create :user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:team) { create :team }
  let(:repository) { create :repository, team: team }
  let(:repository_column) { create :repository_column, :list_type }

  context 'when deletes column' do
    let(:service_call) do
      RepositoryColumns::DeleteColumnService.call(user: user, team: team, column: repository_column)
    end

    it 'removes RepositoryColumn record' do
      repository_column

      expect { service_call }.to change { RepositoryColumn.count }.by(-1)
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.count }.by(1))
    end

    context 'when RepositoryColumn has RepositoryListItems' do
      before do
        3.times do
          create(:repository_list_item, repository: repository, repository_column: repository_column)
        end
      end

      it 'removes RepositoryListItem records as well' do
        expect { service_call }.to(change { RepositoryListItem.count }.by(-3))
      end
    end

    context 'when RepositoryColumn has RepositoryStatusItems' do
      before do
        3.times do
          create(:repository_status_item, repository: repository, repository_column: repository_column)
        end
      end

      it 'removes RepositoryStatusItem records as well' do
        expect { service_call }.to(change { RepositoryStatusItem.count }.by(-3))
      end
    end
  end

  context 'when column cannot be deleted' do
    let(:service_call) do
      RepositoryColumns::DeleteColumnService.call(user: user, team: team, column: repository_column)
    end

    before do
      allow_any_instance_of(RepositoryColumn).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
    end

    it 'returns errors' do
      expect(service_call.errors).to have_key(:repository_column)
    end

    it 'returns succeed false' do
      expect(service_call.succeed?).to be_falsey
    end

    it 'does not add Activity record' do
      expect { service_call }.not_to(change { Activity.count })
    end
  end
end
