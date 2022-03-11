# frozen_string_literal: true

class HiddenRepositoryCellReminder < ApplicationRecord
  belongs_to :repository_cell
  belongs_to :user
end
