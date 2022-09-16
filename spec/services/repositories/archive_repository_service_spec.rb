# frozen_string_literal: true

require 'rails_helper'

describe Repositories::ArchiveRepositoryService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let!(:row_1) { create :repository_row, repository: repository }
  let!(:row_2) { create :repository_row, repository: repository }
  let!(:row_3) { create :repository_row, repository: repository }
  let(:repositories) { [repository] }

  let(:service_call) do
    Repositories::ArchiveRepositoryService.call(repositories: repositories, user: user, team: team)
  end

  context 'when have valid inventory' do
    it 'updates repository archived_by, archived_on, archived' do
      expect { service_call }
        .to(change { repository.reload.archived_on }
        .and(change { repository.archived_by })
        .and(change { repository.archived }))
    end

    it 'creates 1 activity' do
      expect { service_call }.to change { Activity.count }.by(1)
    end
  end

  context 'when have invalid repository' do
    let(:second_repository) do
      r = create :repository, team: team, created_by: user
      r.name = ''
      r.save(validate: false)
      r
    end
    let(:repositories) { [repository, second_repository] }

    it 'does not change repository archived' do
      expect { service_call }.not_to(change { repository.reload.archived_on })
    end

    it 'does not create activity' do
      expect { service_call }.not_to(change { Activity.count })
    end

    it 'returns error' do
      expect(service_call.errors).to have_key(:archiving_error)
    end
  end
end
