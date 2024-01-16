module ArchivableModel
  extend ActiveSupport::Concern

  included do
    validates :archived, inclusion: { in: [true, false] }
    before_save :set_archive_timestamp
    before_save :set_restore_timestamp

    scope :active, -> { where(archived: false) }
    scope :archived, -> { where(archived: true) }
  end

  # Not archived
  def active?
    !archived?
  end

  # Helper for archiving project. Timestamp of archiving is handler by
  # before_save callback.
  # Sets the archived_by value to the current user.
  def archive(current_user)
    self.archived = true
    self.archived_by = current_user
    save
  end

  # Same as archive but raises exception if archive fails.
  # Sets the archived_by value to the current user.
  def archive!(current_user)
    self.archived = true
    self.archived_by = current_user
    save!
  end

  # Helper for restoring project from archive.
  # Sets the restored_by value to the current user.
  def restore(current_user)
    self.archived = false
    self.restored_by = current_user
    save
  end

  # Same as restore but raises exception if restore fails.
  # Sets the restored_by value to the current user.
  def restore!(current_user)
    self.archived = false
    self.restored_by = current_user
    save!
  end

  def name_with_label
    raise NotImplementedError, "Archivable model must implement the '.archived_branch?' method!" unless respond_to?(:archived_branch?)
    return "#{I18n.t('labels.archived')} #{name || parent&.name}" if archived_branch?

    name || parent&.name
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
