# frozen_string_literal: true

class SoftLockedRepository < Repository
  # this is for repositories only editable via API

  enum permission_level: Extends::SHARED_OBJECTS_PERMISSION_LEVELS.except(:shared_write)

  def shareable_write?
    false
  end

  def unlocked?
    @unlocked == true
  end

  def unlock!
    @unlocked = true
  end
end
