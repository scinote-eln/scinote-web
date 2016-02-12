module ArchivableModelTestHelper

  def assert_archived_present(obj)
    assert_not obj.archived.nil?, "Archived attribute must be present."
  end

  def assert_active_is_inverse_of_archived(obj)
    assert_archived_present(obj)
    assert obj.archived? == !obj.active?, "Active attribute isn't inverse of archived attribute."
  end

  # A new object should be provided (one that
  # has never been archived/restored before, but is
  # otherwise valid).
  def archive_and_restore_action_test(obj, user)
    # Check initial values
    assert obj.archived? == false, "New (never archived) #{obj.class}'s archived attribute is not set to 'false' by default."
    assert obj.archived_on.blank?, "New (never archived) #{obj.class}'s archived_on attribute is not blank."
    assert obj.archived_by.blank?, "New (never archived) #{obj.class}'s archived_by attribute is not blank."
    assert_restored_on_blank(obj)
    assert_restored_by_blank(obj)

    # Now, archive the project
    ts = Time.now
    sleep 1
    if user.present?
      obj.archive(user)
      assert obj.archived_by.present?, "#{obj.class}'s archive action didn't set the archived_by attribute."
    else
      obj.archive
    end
    assert obj.archived? == true, "#{obj.class}'s archive action didn't archive it."
    assert (
      obj.archived_on.present? and
      obj.archived_on > ts and
      (obj.archived_on - ts) < 5.seconds
    ), "#{obj.class}'s archive action didn't set archived_on timestamp properly."

    # Make sure restored values are still blank
    assert_restored_on_blank(obj)
    assert_restored_by_blank(obj)

    archived_on_ts = obj.archived_on
    archived_by_user = obj.archived_by

    # Alright, restore the object now
    ts = Time.now
    sleep 1
    if user.present?
      obj.restore(user)
      assert obj.restored_by.present?, "#{obj.class}'s restore action didn't set the restored_by attribute."
    else
      obj.restore
    end
    assert obj.archived? == false, "#{obj.class}'s restore action didn't restore it."
    assert (
      obj.restored_on.present? and
      obj.restored_on > ts and
      (obj.restored_on - ts) < 5.seconds
    ), "#{obj.class}'s restore action didn't set restored_on timestamp properly."

    assert archived_on_ts == obj.archived_on, "#{obj.class}'s restore action changed its archived_on timestamp."
    assert archived_by_user == obj.archived_by, "#{obj.class}'s restore action' changed its archived_by attribute."
  end

  private

  def assert_restored_on_blank(obj)
    assert obj.restored_on.blank?, "New (never restored) #{obj.class}'s restored_on attribute is not blank."
  end

  def assert_restored_by_blank(obj)
    assert obj.restored_by.blank?, "New (never restored) #{obj.class}'s restored_by attribute is not blank."
  end

end