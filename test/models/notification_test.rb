require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  def setup
    @user = users(:john)
    @notification = notificaton(:one)
    @user_notification = UserNotification.new(user: @user,
                                              notificaton: @notificaton)
  end

  should have_db_column(:title).of_type(:string)
  should have_db_column(:message).of_type(:string)
  should have_db_column(:type_of).of_type(:integer)
  should have_db_column(:created_at).of_type(:datetime)
  should have_db_column(:updated_at).of_type(:datetime)
  should have_db_column(:generator_user_id)

  should have_many(:user_notifications)
  should have_many(:users)
  should belong_to(:generator_user).class_name('User')

  test '#already_seen' do
    notifications = Notification.already_seen(@user)
    byebug
    assert notifications.eq([false])
  end
end
