# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.config.x.serverside_sessions_enabled = ENV['SCINOTE_SERVERSIDE_SESSIONS'] == 'true'

session_store = Rails.application.config.x.serverside_sessions_enabled ? :active_record_store : :cookie_store

Rails.application.config.session_store session_store, key: '_scinote_session'

if Rails.application.config.x.serverside_sessions_enabled
  # Store some information about the client on sign in, so the user can recognize their sessions
  Warden::Manager.after_set_user except: :fetch do |user, auth, opts|
    next unless opts[:scope] == :user && user.is_a?(User)

    request = ActionDispatch::Request.new(auth.env)
    auth.raw_session['user_agent'] = request.user_agent.to_s.truncate(512)
    auth.raw_session['ip_address'] = request.remote_ip
    auth.raw_session['signed_in_at'] = Time.current.to_i
  end
end
