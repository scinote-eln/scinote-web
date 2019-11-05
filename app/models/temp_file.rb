# frozen_string_literal: true

class TempFile < ApplicationRecord
  validates :session_id, presence: true

  has_one_attached :file

  class << self
    def destroy_obsolete(temp_file_id)
      temp_file = find_by_id(temp_file_id)
      return unless temp_file.present?

      temp_file.destroy!
    end

    handle_asynchronously :destroy_obsolete, run_at: proc { 7.days.from_now }
  end
end
