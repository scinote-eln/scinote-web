module ArchivableModel
  extend ActiveSupport::Concern

  included do
    validates :archived, inclusion: { in: [true, false] }
    before_save :set_archive_timestamp
    before_save :set_restore_timestamp
  end

  # Not archived
  def active?
    not archived?
  end

  # Helper for archiving project. Timestamp of archiving is handler by
  # before_save callback.
  def archive
    self.archived = true
    save
  end

  # Helper for archiving project. Timestamp of archiving is handler by
  # before_save callback.
  # Sets the archived_by value to the current user.
  def archive (current_user)
    self.archived = true
    self.archived_by = current_user
    save
  end

  # Same as archive but raises exception if archive fails.
  def archive!
    archive || raise(RecordNotSaved)
  end

  # Same as archive but raises exception if archive fails.
  # Sets the archived_by value to the current user.
  def archive!(current_user)
    archive(current_user) || raise(RecordNotSaved)
  end

  # Helper for restoring project from archive.
  def restore
    self.archived = false
    save
  end

  # Helper for restoring project from archive.
  # Sets the restored_by value to the current user.
  def restore (current_user)
    self.archived = false
    self.restored_by = current_user
    save
  end

  # Same as restore but raises exception if restore fails.
  def restore!
    restore || raise(RecordNotSaved)
  end


  # Same as restore but raises exception if restore fails.
  # Sets the restored_by value to the current user.
  def restore!(current_user)
    restore(current_user) || raise(RecordNotSaved)
  end

  protected

  def set_archive_timestamp
    if self.archived_changed?(from: false, to: true)
      self.archived_on = Time.current.to_formatted_s
    end
  end

  def set_restore_timestamp
    if self.archived_changed?(from: true, to: false)
      self.restored_on = Time.current.to_formatted_s
    end
  end
end
