# frozen_string_literal: true

module RepositoryValueWithReminders
  extend ActiveSupport::Concern

  included do
    after_update :clear_hidden_repository_cell_reminders

    private

    def clear_hidden_repository_cell_reminders
      repository_cell.hidden_repository_cell_reminders.delete_all
    end
  end
end
