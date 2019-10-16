# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumns::UpdateListColumnService do
  let(:user) { create :user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:team) { create :team }
  let(:repository) { create :repository, team: team }
  let(:column) { create :repository_column, :list_type }
  let(:list_item) { create(:repository_list_item, repository: repository, repository_column: column) }
  let(:service_call) do
    RepositoryColumns::UpdateListColumnService.call(column: column,
                                                      user: user,
                                                      team: team,
                                                      params: params)
  end

  context 'when updates column' do
    let(:params) { { name: 'my new column' } }

    it 'updates RepositoryColumn record' do
      column

      expect { service_call }.to change(column, :name)
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.count }.by(1))
    end
  end

  context 'when updates column\'s list items ' do
    let(:params) do
      {
        repository_list_items_attributes: [
          { id: list_item.id, data: 'my new list item' }
        ]
      }
    end

    it 'updates list item' do
      expect { service_call }.to(change { list_item.reload.data })
    end

    context 'when deletes list items' do
      let(:params) do
        {
          repository_list_items_attributes: [
            { id: list_item.id, _destroy: true }
          ]
        }
      end

      it 'removes RepositoryListItem record' do
        list_item

        expect { service_call }.to(change { RepositoryListItem.count }.by(-1))
      end
    end

    context 'when valdiations not passed' do
      let(:params) do
        {
          repository_list_items_attributes: [
            { id: list_item.id, data: '' }
          ]
        }
      end

      it 'returns AR errors' do
        expect(service_call.errors).to have_key(:repository_column)
      end

      it 'returns succeed false' do
        expect(service_call.succeed?).to be_falsey
      end
    end
  end
end
