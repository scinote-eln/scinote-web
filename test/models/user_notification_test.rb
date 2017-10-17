require 'test_helper'

class UserNotificationTest < ActiveSupport::TestCase
  should have_db_column(:checked).of_type(:boolean)
  should belong_to(:user)
  should belong_to(:notification)
end
