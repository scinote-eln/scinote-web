# frozen_string_literal: true

require 'rails_helper'

describe UserNotification, type: :model do
  let(:user) { create :user }
  let(:user_notification) { build :user_notification }

  it 'is valid' do
    expect(user_notification).to be_valid
  end

  it 'should be of class UserNotification' do
    expect(subject.class).to eq UserNotification
  end

  describe 'Database table' do
    it { should have_db_column :user_id }
    it { should have_db_column :notification_id }
    it { should have_db_column :checked }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:user).optional }
    it { should belong_to(:notification).optional }
  end

  describe '#unseen_notification_count ' do
    let(:notifcation) { create :notification }
    it 'returns a number of unseen notifications' do
      create :user_notification, user: user, notification: notifcation
      expect(UserNotification.unseen_notification_count(user)).to eq 1
    end
  end

  describe '#recent_notifications' do
    let(:notifcation_one) { create :notification }
    let(:notifcation_two) { create :notification }

    it 'returns a list of notifications ordered by created_at DESC' do
      create :user_notification, user: user, notification: notifcation_one
      create :user_notification, user: user, notification: notifcation_two
      notifications = UserNotification.recent_notifications(user)
      expect(notifications).to eq [notifcation_two, notifcation_one]
    end
  end

  describe '#seen_by_user' do
    let!(:notification) { create :notification }
    let!(:user_notification_one) do
      create :user_notification, user: user, notification: notification
    end

    it 'set the check status to false' do
      expect do
        UserNotification.seen_by_user(user)
      end.to change { user_notification_one.reload.checked }.from(false).to(true)
    end
  end
end
