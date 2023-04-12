# frozen_string_literal: true

class ConnectedDevice < ApplicationRecord
  belongs_to :oauth_access_token, class_name: 'Doorkeeper::AccessToken'
  validates :uid, presence: true

  after_destroy :revoke_token

  def self.for_user(user)
    where(oauth_access_token_id: Doorkeeper::AccessToken.select(:id).where(resource_owner_id: user.id))
  end

  def self.from_request_headers(headers, token = nil)
    return unless headers['Device-Id']

    current_token = Doorkeeper::AccessToken.find_by(
      token: headers['Authorization']&.gsub(/Bearer\s/, '')
    )

    return unless token || current_token

    connected_device = ConnectedDevice.find_or_initialize_by(uid: headers['Device-Id'])
    connected_device.update!(
      name: headers['Device-Name'],
      metadata: {
        os: headers['Device-Os'],
        app_version: headers['Device-App-Version']
      }.compact,
      last_seen_at: Time.current,
      oauth_access_token_id: token&.id || current_token&.id
    )
    connected_device
  end

  private

  def revoke_token
    oauth_access_token.revoke
  end
end
