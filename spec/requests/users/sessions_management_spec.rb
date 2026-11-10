# frozen_string_literal: true

require 'rails_helper'

describe 'Users::SessionsManagement', type: :request do
  let(:user) { create :user, confirmed_at: Time.current }
  let(:other_user) { create :user, confirmed_at: Time.current }
  let(:json) { response.parsed_body }

  around do |example|
    original_value = Rails.configuration.x.serverside_sessions_enabled
    Rails.configuration.x.serverside_sessions_enabled = true
    example.run
  ensure
    Rails.configuration.x.serverside_sessions_enabled = original_value
  end

  let(:test_host) { ENV['USER_SUBDOMAIN'] ? "#{ENV['USER_SUBDOMAIN']}.example.com" : 'www.example.com' }

  before { host! test_host }

  def create_user_session(owner, user_agent: 'Other browser')
    UserSession.create!(
      session_id: "2::#{SecureRandom.hex(32)}",
      data: {
        'warden.user.user.key' => [[owner.id], owner.authenticatable_salt],
        'warden.user.user.session' => { 'last_request_at' => Time.current.to_i },
        'user_agent' => user_agent,
        'ip_address' => '10.0.0.1',
        'signed_in_at' => Time.current.to_i
      }
    )
  end

  def sign_in_with_password(remember_me: false)
    post user_session_path, params: {
      user: { email: user.email, password: user.password, remember_me: remember_me ? '1' : '0' }
    }
  end

  describe 'GET /sessions_management' do
    let!(:other_session) { create_user_session(user) }

    before do
      create_user_session(other_user)
      sign_in_with_password
    end

    it 'returns only sessions of the current user' do
      get sessions_management_index_path(format: :json)

      expect(response).to have_http_status(:ok)
      expect(json['data'].pluck('id')).to include(other_session.id)
      expect(json['data'].pluck('id')).to match_array(UserSession.for_user(user).pluck(:id))
      expect(json['data'].find { |s| s['id'] == other_session.id }).to include(
        'user_agent' => 'Other browser',
        'ip_address' => '10.0.0.1',
        'current' => false
      )
    end

    it 'excludes expired sessions' do
      other_session.update_columns(updated_at: (user.timeout_in + 1.minute).ago)

      get sessions_management_index_path(format: :json)

      expect(json['data'].pluck('id')).not_to include(other_session.id)
    end

    it 'returns 404 when server-side sessions are disabled' do
      Rails.configuration.x.serverside_sessions_enabled = false

      get sessions_management_index_path(format: :json)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /sessions_management/:id' do
    let!(:other_session) { create_user_session(user) }

    it 'deletes the session' do
      sign_in_with_password

      expect do
        delete sessions_management_path(other_session.id, format: :json)
      end.to change { UserSession.exists?(other_session.id) }.from(true).to(false)
      expect(response).to have_http_status(:ok)
    end

    it 'does not delete sessions of other users' do
      foreign_session = create_user_session(other_user)
      sign_in_with_password

      delete sessions_management_path(foreign_session.id, format: :json)

      expect(response).to have_http_status(:not_found)
      expect(UserSession.exists?(foreign_session.id)).to be true
    end

    it 'invalidates remember me tokens issued to other browsers' do
      user.remember_me!
      other_browser_token = User.serialize_into_cookie(user.reload)
      sign_in_with_password

      delete sessions_management_path(other_session.id, format: :json)

      expect(user.reload.remember_me?(other_browser_token[1], other_browser_token[2])).to be false
    end

    it 'keeps remember me working for the current browser' do
      sign_in_with_password(remember_me: true)
      expect(cookies['remember_user_token']).to be_present

      delete sessions_management_path(other_session.id, format: :json)

      expect(cookies['remember_user_token']).to be_present
      expect(user.reload.remember_created_at).to be_present
    end

    it 'returns 401 when not signed in' do
      delete sessions_management_path(other_session.id, format: :json)

      expect(response).to have_http_status(:unauthorized)
      expect(UserSession.exists?(other_session.id)).to be true
    end
  end

  describe 'DELETE /sessions_management/destroy_others' do
    it 'deletes all sessions of the current user except the current one' do
      user_sessions = [create_user_session(user), create_user_session(user)]
      foreign_session = create_user_session(other_user)
      sign_in_with_password

      delete destroy_others_sessions_management_index_path(format: :json)

      expect(response).to have_http_status(:ok)
      expect(UserSession.where(id: user_sessions.map(&:id))).to be_empty
      expect(UserSession.exists?(foreign_session.id)).to be true

      get sessions_management_index_path(format: :json)
      expect(response).to have_http_status(:ok)
    end
  end

  # Full flow with two separate browsers. The session store middleware is picked at boot, so this
  # only runs when the suite is started with SCINOTE_SERVERSIDE_SESSIONS=true.
  describe 'terminating a session from another browser', :aggregate_failures do
    before do
      skip 'requires SCINOTE_SERVERSIDE_SESSIONS=true' unless Rails.application.config.session_store == ActionDispatch::Session::ActiveRecordStore
    end

    def new_browser
      open_session.tap { |browser| browser.host! test_host }
    end

    def sign_in_browser(browser, remember_me:)
      browser.post user_session_path,
                   params: { user: { email: user.email, password: user.password,
                                     remember_me: remember_me ? '1' : '0' } },
                   headers: { 'User-Agent' => "Browser #{browser.object_id}" }
    end

    def signed_in?(browser)
      browser.get sessions_management_index_path(format: :json)
      browser.response.status == 200
    end

    %w(true false).each do |remember_me|
      it "logs out the terminated browser (remember me: #{remember_me})" do
        browser_a = new_browser
        browser_b = new_browser
        sign_in_browser(browser_a, remember_me: remember_me == 'true')
        sign_in_browser(browser_b, remember_me: remember_me == 'true')

        expect(signed_in?(browser_a)).to be true
        expect(signed_in?(browser_b)).to be true

        browser_a.get sessions_management_index_path(format: :json)
        sessions = browser_a.response.parsed_body['data']
        expect(sessions.size).to eq 2
        expect(sessions.find { |s| s['current'] }['user_agent']).to eq "Browser #{browser_a.object_id}"
        session_b = sessions.find { |s| !s['current'] }
        expect(session_b['user_agent']).to eq "Browser #{browser_b.object_id}"

        browser_a.delete session_b['destroy_url'], as: :json
        expect(browser_a.response).to have_http_status(:ok)

        expect(signed_in?(browser_b)).to be false
        expect(signed_in?(browser_a)).to be true
      end
    end

    it 'logs out all other browsers' do
      browser_a = new_browser
      browser_b = new_browser
      browser_c = new_browser
      [browser_a, browser_b, browser_c].each { |browser| sign_in_browser(browser, remember_me: true) }

      browser_a.delete destroy_others_sessions_management_index_path(format: :json)

      expect(signed_in?(browser_b)).to be false
      expect(signed_in?(browser_c)).to be false
      expect(signed_in?(browser_a)).to be true
    end

    it 'does not allow terminating the current session' do
      browser = new_browser
      sign_in_browser(browser, remember_me: false)
      browser.get sessions_management_index_path(format: :json)
      current_session = browser.response.parsed_body['data'].find { |s| s['current'] }

      browser.delete current_session['destroy_url'], as: :json

      expect(browser.response).to have_http_status(:unprocessable_content)
      expect(signed_in?(browser)).to be true
    end
  end
end
