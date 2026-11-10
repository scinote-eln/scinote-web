# frozen_string_literal: true

# Server-side session records (used when SCINOTE_SERVERSIDE_SESSIONS=true),
# so that users can list and terminate their sessions.
class UserSession < ActiveRecord::SessionStore::Session
  WARDEN_USER_SESSION_KEY = 'warden.user.user.session'

  # The session store saves session data as a JSON string ({"value": {...}}) into the jsonb column,
  # so it has to be parsed first. Devise/Warden serializes the user as [[id], authenticatable_salt].
  USER_ID_SQL = "(sessions.data #>> '{}')::jsonb #>> '{value,warden.user.user.key,0,0}'"

  # User#timeout_in can be overridden by organization settings
  scope :active, ->(user) { where(updated_at: user.timeout_in.ago..) }
  scope :for_user, ->(user) { where("#{USER_ID_SQL} = ?", user.id.to_s) }

  def self.current_session_ids(request)
    session_id = request.session.id
    return [] if session_id.blank?

    [session_id.private_id, session_id.public_id]
  end

  def user_agent
    data['user_agent']
  end

  def ip_address
    data['ip_address']
  end

  def signed_in_at
    data['signed_in_at'] ? Time.zone.at(data['signed_in_at']) : created_at
  end

  def last_seen_at
    last_request_at = data.dig(WARDEN_USER_SESSION_KEY, 'last_request_at')
    last_request_at ? Time.zone.at(last_request_at) : updated_at
  end
end
