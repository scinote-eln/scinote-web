# Be sure to restart your server when you modify this file.

session_store = ENV['SCINOTE_SERVERSIDE_SESSIONS'] == 'true' ? :active_record_store : :cookie_store

Rails.application.config.session_store session_store, key: '_scinote_session'
