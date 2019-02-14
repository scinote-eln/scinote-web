# frozen_string_literal: true

require 'rails_helper'

describe UserSystemNotification do
  let(:user) { create :user }
  subject(:user_system_notification) { build :user_system_notification }

  it 'is valid' do
    expect(user_system_notification).to be_valid
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:system_notification) }
  end

  describe '.send_email' do
    before do
      Delayed::Worker.delay_jobs = false
    end

    after do
      Delayed::Worker.delay_jobs = true
    end

    context 'when user has enabled notifications' do
      it 'delivers an email on creating new user_system_notification' do
        allow(user_system_notification.user)
          .to receive(:system_message_email_notification).and_return(true)

        expect { user_system_notification.save }
          .to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'when user has disabled notifications' do
      it 'doesn\'t deliver email on creating new user_system_notification' do
        allow(user_system_notification.user)
          .to receive(:system_message_email_notification).and_return(false)

        expect { user_system_notification.save }
          .not_to(change { ActionMailer::Base.deliveries.count })
      end
    end
  end

  describe 'Methods' do
    let(:notifcation_one) { create :system_notification }
    let(:notifcation_two) { create :system_notification }
    let(:notifcation_three) { create :system_notification, :show_on_login }

    it 'make_as_seen update seen_at' do
      usn = create :user_system_notification,
                   user: user,
                   system_notification: notifcation_one
      notifications_to_update = [usn.system_notification_id]
      user.user_system_notifications.mark_as_seen(notifications_to_update)
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
