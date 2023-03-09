# frozen_string_literal: true

require 'rails_helper'

describe RepositoryActions::ArchiveRowsService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:row_1) { create :repository_row, repository: repository }
  let(:row_2) { create :repository_row, repository: repository }
  let(:row_3) { create :repository_row, repository: repository }
  let(:repository_rows_ids) { [row_1, row_2, row_3].map(&:id) }

  let(:service_call) do
    RepositoryActions::ArchiveRowsService.call(repository: repository,
                                               user: user,
                                               repository_rows: repository_rows_ids,
                                               team: team)
  end

  context 'when have no rows' do
    let(:repository_rows_ids) { [] }

    it 'returns errors for no rows' do
      expect(service_call.errors).to have_key(:repository_rows)
    end
  end

  context 'when have rows' do
    it 'update rows archived_by, archived_on, archived' do
      expect { service_call }
        .to(change { row_1.reload.archived_on }
              .and(change { row_1.archived_by })
              .and(change { row_1.archived }))
    end

    it 'creates 3 activities' do
      expect { service_call }.to change { Activity.count }.by(3)
    end
  end

  context 'when have invalid item' do
    let(:invalid_row) do
      r = create :repository_row, repository: repository, created_by: user
      r.name = ''
      r.save(validate: false)
      r
    end

    let(:repository_rows_ids) { [row_1, row_2, row_3, invalid_row].map(&:id) }

    it 'rollback all archived items' do
      expect { service_call }.not_to(change { row_1.reload.archived_on })
    end

    it 'destory created activities' do
      expect { service_call }.to change { Activity.count }.by(0)
    end

    it 'returns error' do
      expect(service_call.errors).to have_key(:archiving_error)
    end
  end

  context 'when want to archive already archived row' do
    let(:archived_item) { create :repository_row, :archived, repository: repository }
    let(:repository_rows_ids) { [archived_item.id] }

    it 'returns errors for no rows because its ignored' do
      expect(service_call.errors).to have_key(:repository_rows)
    end
  end
end
