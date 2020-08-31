# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumns::CreateColumnService do
  let(:user) { create :user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:team) { create :team }
  let(:repository) { create :repository, team: team }
  let(:column_type) { :RepositoryStatusValue }
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

  let(:service_call) do
    RepositoryColumns::CreateColumnService.call(repository: repository,
                                                user: user,
                                                team: team,
                                                column_type: column_type,
                                                params: params)
  end

  context 'when creates new column' do
    it 'adds RepositoryColumn record' do
      expect { service_call }.to change { RepositoryColumn.count }.by(1)
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.count }.by(1))
    end
  end

  context 'when has invalid record' do
    let(:params) do
      {
        name: ''
      }
    end

    it 'returns AR errors' do
      expect(service_call.errors).to have_key(:repository_column)
    end

    it 'returns succeed false' do
      expect(service_call.succeed?).to be_falsey
    end
  end

  context 'whem repository is nil' do
    let(:repository) { nil }

    it 'returns invalid_arugments error' do
      expect(service_call.errors).to have_key(:invalid_arguments)
    end

    it 'returns succeed false' do
      expect(service_call.succeed?).to be_falsey
    end
  end

  context 'when column has StatusItems' do
    let(:column_type) { :RepositoryStatusValue }
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

    it 'adds RepositoryStatusItem record' do
      expect { service_call }.to(change { RepositoryStatusItem.count }.by(3))
    end

    context 'when has invalid StatusItem' do
      let(:params) do
        {
          name: 'myrepo',
          repository_status_items_attributes: [
            { status: 'first', icon: 'some icon' },
            { status: '', icon: 'some icon' },
            { status: 'third', icon: 'some icon' }
          ]
        }
      end

      it 'returns AR errors' do
        expect(service_call.errors).to have_key(:repository_column)
      end
    end
  end

  context 'when column has ListItems' do
    let(:params) do
      {
        name: 'myrepo',
        repository_list_items_attributes: [
          { data: 'first' },
          { data: 'second' },
          { data: 'third' }
        ]
      }
    end

    it 'adds RepositoryListItem record' do
      expect { service_call }.to(change { RepositoryListItem.count }.by(3))
    end

    context 'when has invalid ListItem' do
      let(:params) do
        {
          name: 'name',
          repository_list_items_attributes: [
            { data: '' },
            { data: 'second' },
            { data: 'third' }
          ]
        }
      end

      it 'returns AR errors' do
        expect(service_call.errors).to have_key(:repository_column)
      end
    end
  end
end
