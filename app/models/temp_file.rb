class TempFile < ApplicationRecord
  validates :session_id, presence: true

  has_attached_file :file
  do_not_validate_attachment_file_type :file

  def destroy_obsolete
    destroy! if self
  end

  handle_asynchronously :destroy_obsolete,
                        run_at: proc { 7.days.from_now }
end
