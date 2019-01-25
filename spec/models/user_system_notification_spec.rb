# frozen_string_literal: true

require 'rails_helper'

describe UserSystemNotification do
  subject(:user_system_notification) { build :user_system_notification }

  it 'is valid' do
    expect(user_system_notification).to be_valid
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:system_notification) }
  end
end
