# frozen_string_literal: true

require 'rails_helper'

describe Repositories::RestoreRepositoryService do
  let(:user) { create :user }
  let(:team) { create :team }
  let(:repository) { create :repository, :archived, team: team }
  let!(:row_1) { create :repository_row, :archived, repository: repository }
  let!(:row_2) { create :repository_row, :archived, repository: repository }
  let!(:row_3) { create :repository_row, :archived, repository: repository }
  let(:repositories) { [repository] }

  let(:service_call) do
    Repositories::RestoreRepositoryService.call(repositories: repositories, user: user, team: team)
  end

  context 'when have inventory with rows' do
    it 'updates repository restored_by, restored_on, archived' do
      expect { service_call }
        .to(change { repository.reload.restored_on }
              .and(change { repository.restored_by })
              .and(change { repository.archived }))
    end

    it 'update rows restored_by, restored_on, archived' do
      expect { service_call }
        .to(change { row_1.reload.restored_on }
              .and(change { row_1.restored_by })
              .and(change { row_1.archived }))
    end

    it 'creates 1 activity' do
      expect { service_call }.to change { Activity.count }.by(1)
    end

    context 'when have restored row' do
      let!(:row_1) do
        create :repository_row, :restored, repository: repository
      end

      it 'does not update row\'s restored_on' do
        row_1.restored_on = Time.zone.now - 10.days
        row_1.save

        expect { service_call }.not_to(change { row_1.reload.restored_on })
      end
    end
  end

  context 'when includes invalid repository' do
    let(:second_repository) do
      r = create :repository, :archived, team: team
      r.name = ''
      r.save(validate: false)
      r
    end
    let(:repositories) { [repository, second_repository] }

    it 'does not change repository restored_on' do
      expect { service_call }.not_to(change { repository.reload.restored_on })
    end

    it 'does not create activity' do
      expect { service_call }.not_to(change { Activity.count })
    end

    it 'returns error' do
      expect(service_call.errors).to have_key(:restoring_error)
    end
  end

  context 'when have invalid item' do
    let!(:row_1) do
      r = create :repository_row, :archived, repository: repository
      r.name = ''
      r.save(validate: false)
      r
    end

    it 'restore item anyway' do
      expect { service_call }.to(change { row_1.reload.restored_on })
    end

    it 'creates one activity' do
      expect { service_call }.to change { Activity.count }.by(1)
    end
  end
end
