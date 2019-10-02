# frozen_string_literal: true

class TempFile < ApplicationRecord
  validates :session_id, presence: true

  has_one_attached :file

  def file_service_url
    ActiveStorage::Current.set(host: Rails.application.secrets.mail_server_url) do
      file.service_url
    end
  end

  class << self
    def destroy_obsolete(temp_file_id)
      temp_file = find_by_id(temp_file_id)
      return unless temp_file.present?

      temp_file.destroy!
    end

    handle_asynchronously :destroy_obsolete, run_at: proc { 7.days.from_now }
  end
end
