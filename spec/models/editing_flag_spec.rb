# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditingFlag, type: :model do
  let(:user) { create :user }
  let(:step) { create :step }

  describe 'validations' do
    it 'is invalid without a timeout_at' do
      editing_flag = build(:editing_flag, user: user, subject: step, timeout_at: nil)
      expect(editing_flag).not_to be_valid
    end

    it 'is invalid when the user already has an active flag for the same subject' do
      create(:editing_flag, user: user, subject: step, timeout_at: 1.minute.from_now)
      duplicate = build(:editing_flag, user: user, subject: step, timeout_at: 1.minute.from_now)

      expect(duplicate).not_to be_valid
    end
  end

  describe '.active' do
    it 'includes only flags with a future timeout_at' do
      active_flag = create(:editing_flag, subject: step, timeout_at: 1.minute.from_now)
      create(:editing_flag, subject: create(:step), timeout_at: 1.minute.ago)

      expect(EditingFlag.active).to contain_exactly(active_flag)
    end
  end

  describe '.expired' do
    it 'includes only flags with a past timeout_at' do
      expired_flag = create(:editing_flag, subject: step, timeout_at: 1.minute.ago)
      create(:editing_flag, subject: create(:step), timeout_at: 1.minute.from_now)

      expect(EditingFlag.expired).to contain_exactly(expired_flag)
    end
  end

  describe 'broadcasting' do
    it 'broadcasts to the subject stream on create' do
      expect(EditingFlagsChannel).to receive(:broadcast_to).with(step, hash_including(action: 'create'))

      create(:editing_flag, user: user, subject: step, timeout_at: 1.minute.from_now)
    end

    it 'broadcasts to the subject stream when timeout_at is refreshed' do
      editing_flag = create(:editing_flag, user: user, subject: step, timeout_at: 1.minute.from_now)

      expect(EditingFlagsChannel).to receive(:broadcast_to).with(step, hash_including(action: 'refresh'))

      editing_flag.update(timeout_at: 2.minutes.from_now)
    end

    it 'does not broadcast or raise when the subject has already been destroyed' do
      editing_flag = create(:editing_flag, user: user, subject: step, timeout_at: 1.minute.from_now)
      step.destroy

      expect(EditingFlagsChannel).not_to receive(:broadcast_to)
      expect { editing_flag.destroy }.not_to raise_error
    end
  end
end
