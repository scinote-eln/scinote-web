# frozen_string_literal: true

require 'rails_helper'

describe Repositories::MultipleShareUpdateService do
  let(:user) { create :user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:team) { create :team }
  let(:team2) { create :team }
  let(:team3) { create :team }
  let(:repository) { create :repository, team: team }

  context 'when share' do
    let(:service_call) do
      Repositories::MultipleShareUpdateService.call(repository: repository,
                                                    user: user,
                                                    team: team,
                                                    team_ids_for_share: [{ id: team2.id, permission_level: :shared_read }])
    end

    it 'adds TeamRepository record' do
      expect { service_call }.to change { TeamRepository.count }.by(1)
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.all.count }.by(1))
    end

    context 'when cannot generate share' do
      let(:service_call) do
        Repositories::MultipleShareUpdateService.call(repository: repository,
                                                      user: user,
                                                      team: team,
                                                      team_ids_for_share: [{ id: -1, permission_level: :shared_read }])
      end

      it 'returns error' do
        expect(service_call.warnings.count).to eq(1)
      end
    end
  end

  context 'when unshare' do
    let(:service_call) do
      Repositories::MultipleShareUpdateService.call(repository: repository,
                                                    user: user,
                                                    team: team,
                                                    team_ids_for_unshare: [team2.id])
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
        Repositories::MultipleShareUpdateService.call(repository: repository,
                                                      user: user,
                                                      team: team,
                                                      team_ids_for_unshare: [-1])
      end

      it 'returns error' do
        expect(service_call.warnings.count).to eq(1)
      end
    end
  end

  context 'when updates share permissions' do
    let(:service_call) do
      Repositories::MultipleShareUpdateService.call(
        repository: repository,
        user: user,
        team: team,
        team_ids_for_update: [{ id: team2.id, permission_level: :shared_read }]
      )
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
        Repositories::MultipleShareUpdateService.call(repository: repository,
                                                      user: user,
                                                      team: team,
                                                      team_ids_for_update: [{ id: -1, permission_level: :shared_read }])
      end

      it 'returns error' do
        expect(service_call.warnings.count).to eq(1)
      end
    end
  end

  context 'when share_with_all' do
    let(:service_call) do
      Repositories::MultipleShareUpdateService.call(repository: repository,
                                                    user: user,
                                                    team: team,
                                                    shared_with_all: true,
                                                    shared_permissions_level: :shared_write)
    end

    it 'updates permission for share record' do
      expect { service_call }.to(change { repository.reload.permission_level })
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.all.count }.by(1))
    end
  end
end
