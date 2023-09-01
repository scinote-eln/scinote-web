# frozen_string_literal: true

class HideRepositoryRemindersJob < ApplicationJob
  queue_as :high_priority

  def perform(repository, user_id)
    user = User.find(user_id)
    hidden_reminder_repository_cell_ids =
      HiddenRepositoryCellReminder.joins(repository_cell: { repository_row: :repository })
                                  .where(user: user)
                                  .where(repositories: { id: repository.id })
                                  .select(:id)

    repository_cell_ids =
      RepositoryCell.joins(repository_row: :repository)
                    .where.not(id: hidden_reminder_repository_cell_ids)
                    .with_active_reminder(user).where(repositories: { id: repository.id })
                    .pluck(:id)

    HiddenRepositoryCellReminder.import(
      repository_cell_ids.map { |rid| { repository_cell_id: rid, user_id: user.id } }
    )
  end
end
