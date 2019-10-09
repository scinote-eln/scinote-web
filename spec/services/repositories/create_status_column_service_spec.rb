# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumns::CreateStatusColumnService do
  let(:user) { create :user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:team) { create :team }
  let(:repository) { create :repository, team: team }
  let(:params) do
    {
      name: 'myrepo',
      repository_status_items_attributes: [
        { status: 'first', icon: 'some icon' },
        { status: 'second', icon: 'some icon' },
        { status: 'third', icon: 'some icon' }
      ]
    }
  end

  context 'when creates new status column' do
    let(:service_call) do
      RepositoryColumns::CreateStatusColumnService.call(repository: repository,
                                                    user: user,
                                                    team: team,
                                                    params: params)
    end

    it 'adds RepositoryColumn record' do
      expect { service_call }.to change { RepositoryColumn.count }.by(1)
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.count }.by(1))
    end

    it 'adds RepositoryStatusItem record' do
      expect { service_call }.to(change { RepositoryStatusItem.count }.by(3))
    end
  end

  context 'when has invalid record' do
    let(:params) do
      {
        name: '',
        repository_status_items_attributes: [
          { status: '', icon: 'some icon' },
          { status: 'second', icon: 'some icon' },
          { status: 'third' }
        ]
      }
    end

    let(:service_call) do
      RepositoryColumns::CreateStatusColumnService.call(repository: repository,
                                                   user: user,
                                                   team: team,
                                                   params: params)
    end

    it 'returns AR errors' do
      expect(service_call.errors).to have_key(:repository_column)
    end

    it 'returns succeed false' do
      expect(service_call.succeed?).to be_falsey
    end
  end

  context 'whem repository is nil' do
    let(:service_call) do
      RepositoryColumns::CreateStatusColumnService.call(repository: nil,
                                                        user: user,
                                                        team: team,
                                                        params: params)
    end

    it 'returns invalid_arugments error' do
      expect(service_call.errors).to have_key(:invalid_arguments)
    end

    it 'returns succeed false' do
      expect(service_call.succeed?).to be_falsey
    end
  end
end
