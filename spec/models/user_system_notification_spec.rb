# frozen_string_literal: true

require 'rails_helper'

describe UserSystemNotification do
  let(:user_system_notification) { build :user_system_notification }

  it 'is valid' do
    expect(user_system_notification).to be_valid
  end

  describe 'Associations' do
    it { should belong_to :user }
    it { should belong_to :system_notification }
  end

  describe 'Methods' do
    let(:user) { create :user }
    let(:notifcation_one) { create :system_notification }
    let(:notifcation_two) { create :system_notification }
    let(:notifcation_three) { create :system_notification, :show_on_login }

    it 'make_as_seen update seen_at' do
      usn = create :user_system_notification,
                   user: user,
                   system_notification: notifcation_one
      notifications_to_update = [usn.system_notification_id]
      user.user_system_notifications.mark_as_seen
      expect(UserSystemNotification.find(usn.id).seen_at).not_to be_nil
    end

    it 'make_as_read update read_at' do
      usn = create :user_system_notification,
                   user: user,
                   system_notification: notifcation_one
      user.user_system_notifications.mark_as_read(usn.system_notification_id)
      expect(UserSystemNotification.find(usn.id).read_at).not_to be_nil
    end

    it 'show_on_login method only check any notifications' do
      usn = create :user_system_notification,
                   user: user,
                   system_notification: notifcation_three
      result = user.user_system_notifications.show_on_login
      expect(result).not_to be_nil
      expect(UserSystemNotification.find(usn.id).seen_at).to be_nil
      expect(UserSystemNotification.find(usn.id).read_at).to be_nil
    end

    it 'show_on_login method update notification read and seen time' do
      usn = create :user_system_notification,
                   user: user,
                   system_notification: notifcation_three
      result = user.user_system_notifications.show_on_login(true)
      expect(result).not_to be_nil
      expect(UserSystemNotification.find(usn.id).seen_at).not_to be_nil
      expect(UserSystemNotification.find(usn.id).read_at).not_to be_nil
    end
  end
end
