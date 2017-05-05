class TempFile < ActiveRecord::Base
  validates :session_id, presence: true

  has_attached_file :file
  do_not_validate_attachment_file_type :file

  def destroy_obsolete_files
    file = TempFile.find_by_id(self.id)
    file.destroy! if file
  end

  handle_asynchronously :destroy_obsolete_files,
                        run_at: proc { 7.days.from_now }
end
