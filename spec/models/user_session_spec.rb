# frozen_string_literal: true

require 'rails_helper'

describe UserSession, type: :model do
  let(:user) { create :user }

  def create_session(data = {})
    UserSession.create!(session_id: "2::#{SecureRandom.hex(32)}", data: data)
  end

  describe '.for_user' do
    let(:other_user) { create :user }

    it 'returns only sessions of the given user' do
      user_session = create_session('warden.user.user.key' => [[user.id], 'salt'])
      other_user_session = create_session('warden.user.user.key' => [[other_user.id], 'salt'])
      anonymous_session = create_session('_csrf_token' => 'token')

      expect(UserSession.for_user(user)).to contain_exactly(user_session)
      expect(UserSession.for_user(other_user)).to contain_exactly(other_user_session)
      expect(UserSession.for_user(user)).not_to include(anonymous_session)
    end

    it 'does not return sessions after user signs out' do
      user_session = create_session('warden.user.user.key' => [[user.id], 'salt'])
      user_session.update!(data: {})

      expect(UserSession.for_user(user)).to be_empty
    end

    it 'does not match on partial ids' do
      create_session('warden.user.user.key' => [[user.id * 10], 'salt'])

      expect(UserSession.for_user(user)).to be_empty
    end
  end

  describe 'client information' do
    let(:last_request_at) { 5.minutes.ago.to_i }
    let(:signed_in_at) { 1.hour.ago.to_i }
    let(:user_session) do
      UserSession.find(
        create_session(
          'warden.user.user.key' => [[user.id], 'salt'],
          'warden.user.user.session' => { 'last_request_at' => last_request_at },
          'user_agent' => 'Mozilla/5.0 Test',
          'ip_address' => '10.0.0.1',
          'signed_in_at' => signed_in_at
        ).id
      )
    end

    it 'exposes stored values' do
      expect(user_session.user_agent).to eq 'Mozilla/5.0 Test'
      expect(user_session.ip_address).to eq '10.0.0.1'
      expect(user_session.signed_in_at.to_i).to eq signed_in_at
      expect(user_session.last_seen_at.to_i).to eq last_request_at
    end

    it 'falls back to timestamps when values are missing' do
      user_session = create_session

      expect(user_session.signed_in_at).to eq user_session.created_at
      expect(user_session.last_seen_at).to eq user_session.updated_at
    end
  end

  describe '.active' do
    let(:active_session) { create_session }
    let(:expired_session) { create_session }

    it 'excludes sessions idle longer than user timeout' do
      expired_session.update_columns(updated_at: (user.timeout_in + 1.minute).ago)

      expect(UserSession.active(user)).to include(active_session)
      expect(UserSession.active(user)).not_to include(expired_session)
    end

    it 'respects user specific timeout' do
      allow(user).to receive(:timeout_in).and_return(10.minutes)
      expired_session.update_columns(updated_at: 11.minutes.ago)

      expect(UserSession.active(user)).to include(active_session)
      expect(UserSession.active(user)).not_to include(expired_session)
    end
  end
end
