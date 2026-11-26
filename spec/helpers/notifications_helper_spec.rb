# frozen_string_literal: true

require 'rails_helper'

describe NotificationsHelper, type: :helper do
  let(:user) { create :user }
  let(:target_user) { create :user }
  let(:team) { create :team, created_by: user }

  describe '#send_email_notification' do
    it 'delays the notification mail for the user' do
      notification = double('notification')
      delayed = double('delayed')
      allow(AppMailer).to receive(:delay).and_return(delayed)
      expect(delayed).to receive(:notification).with(user.id, notification)

      helper.send_email_notification(user, notification)
    end
  end

  describe '#generate_notification' do
    it 'sends an invite notification when a role is given' do
      expect(GeneralNotification).to receive(:send_notifications).with(
        hash_including(
          type: :invite_user_to_team,
          title: "<i>#{target_user.name}</i> was added as Owner to workspace <strong>#{team.name}</strong> by <i>#{user.name}</i>.",
          subject_id: team.id,
          subject_class: 'Team',
          subject_name: team.name,
          user_id: target_user.id
        )
      )

      helper.generate_notification(user, target_user, team, 'Owner')
    end

    it 'sends a removal notification without a role' do
      expect(GeneralNotification).to receive(:send_notifications).with(
        hash_including(type: :remove_user_from_team, user_id: target_user.id, subject_id: team.id)
      )

      helper.generate_notification(user, target_user, team, nil)
    end
  end
end
