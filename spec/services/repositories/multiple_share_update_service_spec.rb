# frozen_string_literal: true

require 'rails_helper'

describe Repositories::MultipleShareUpdateService do
  let(:user) { create :user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:team) { create :team }
  let(:team2) { create :team }
  let(:team3) { create :team }
  let(:repository) { create :repository, team: team }

  context 'when user do not have permissions' do
    it 'returns error about permissions' do
      new_repo = create :repository
      service_call = Repositories::MultipleShareUpdateService.call(repository_id: new_repo.id,
                                                                   user_id: user.id,
                                                                   team_id: team.id)

      expect(service_call.errors).to have_key(:user_without_permissions)
    end
  end

  context 'when repository not found' do
    it 'returns error about repository' do
      service_call = Repositories::MultipleShareUpdateService.call(repository_id: -1,
                                                                   user_id: user.id,
                                                                   team_id: team.id)

      expect(service_call.errors).to have_key(:invalid_arguments)
    end
  end

  context 'when share' do
    let(:service_call) do
      Repositories::MultipleShareUpdateService.call(repository_id: repository.id,
                                                    user_id: user.id,
                                                    team_id: team.id,
                                                    team_ids_for_share: [{ id: team2.id, permission_level: 'read' }])
    end

    it 'adds TeamRepository record' do
      expect { service_call }.to change { TeamRepository.count }.by(1)
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.all.count }.by(1))
    end

    context 'when cannot generate share' do
      let(:service_call) do
        Repositories::MultipleShareUpdateService.call(repository_id: repository.id,
                                                      user_id: user.id,
                                                      team_id: team.id,
                                                      team_ids_for_share: [{ id: -1, permission_level: 'read' }])
      end

      it 'returns error' do
        expect(service_call.errors[:shares].count).to eq(1)
      end
    end
  end

  context 'when unshare' do
    let(:service_call) do
      Repositories::MultipleShareUpdateService.call(repository_id: repository.id,
                                                    user_id: user.id,
                                                    team_id: team.id,
                                                    team_ids_for_unshare: [{ id: team2.id }])
    end

    it 'removes TeamRepository record' do
      create :team_repository, :write, team: team2, repository: repository

      expect { service_call }.to change { TeamRepository.count }.by(-1)
    end

    it 'adds Activity record' do
      create :team_repository, :write, team: team2, repository: repository

      expect { service_call }.to(change { Activity.all.count }.by(1))
    end

    context 'when cannot delete share' do
      let(:service_call) do
        Repositories::MultipleShareUpdateService.call(repository_id: repository.id,
                                                      user_id: user.id,
                                                      team_id: team.id,
                                                      team_ids_for_unshare: [{ id: -1 }])
      end

      it 'returns error' do
        expect(service_call.errors[:shares].count).to eq(1)
      end
    end
  end

  context 'when updates share permissions' do
    let(:service_call) do
      Repositories::MultipleShareUpdateService.call(repository_id: repository.id,
                                                    user_id: user.id,
                                                    team_id: team.id,
                                                    team_ids_for_update: [{ id: team2.id, permission_level: 'read' }])
    end

    it 'updates permission for share record' do
      tr = create :team_repository, :write, team: team2, repository: repository

      expect { service_call }.to(change { tr.reload.permission_level })
    end

    it 'adds Activity record' do
      create :team_repository, :write, team: team2, repository: repository

      expect { service_call }.to(change { Activity.all.count }.by(1))
    end

    context 'when cannot update share' do
      let(:service_call) do
        Repositories::MultipleShareUpdateService.call(repository_id: repository.id,
                                                      user_id: user.id,
                                                      team_id: team.id,
                                                      team_ids_for_update: [{ id: -1, permission_level: 'read' }])
      end

      it 'returns error' do
        expect(service_call.errors[:shares].count).to eq(1)
      end
    end
  end
end
