# frozen_string_literal: true

require 'rails_helper'

describe HideRepositoryRemindersJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }

  it 'raises for an unknown user' do
    expect { described_class.perform_now(repository, 0) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'does nothing when there are no active reminders' do
    expect { described_class.perform_now(repository, user.id) }.not_to change(HiddenRepositoryCellReminder, :count)
  end

  context 'with stock cells' do
    let(:row) { create :repository_row, repository: repository, created_by: user, last_modified_by: user }
    let(:other_row) { create :repository_row, repository: repository, created_by: user, last_modified_by: user }
    let(:stock_column) { repository.repository_columns.find_by(data_type: 'RepositoryStockValue') || create(:repository_column, :stock_type, repository: repository) }
    let!(:low_cell) do
      cell = create :repository_cell, :stock_value, repository_row: row, repository_column: stock_column
      cell.value.update_columns(amount: 0)
      cell
    end
    let!(:full_cell) { create :repository_cell, :stock_value, repository_row: other_row, repository_column: stock_column }

    it 'hides only the active reminders of the repository for the user, once' do
      expect { described_class.perform_now(repository, user.id) }
        .to change { HiddenRepositoryCellReminder.where(user: user, repository_cell: low_cell).count }.from(0).to(1)
      expect(HiddenRepositoryCellReminder.where(repository_cell: full_cell)).to be_empty

      expect { described_class.perform_now(repository, user.id) }.not_to change(HiddenRepositoryCellReminder, :count)
    end
  end
end
