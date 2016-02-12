class TempFile < ActiveRecord::Base
  validates :session_id, presence: true

  has_attached_file :file
  do_not_validate_attachment_file_type :file
end
