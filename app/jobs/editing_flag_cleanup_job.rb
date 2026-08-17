# frozen_string_literal: true

class EditingFlagCleanupJob < ApplicationJob
  def perform
    EditingFlag.expired.find_each(&:destroy)
  end
end
