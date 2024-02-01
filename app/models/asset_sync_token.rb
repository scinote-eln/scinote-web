# frozen_string_literal: true

class AssetSyncToken < ApplicationRecord
  belongs_to :user
  belongs_to :asset

  after_initialize :generate_token
  after_initialize :set_default_expiration

  validates :token, uniqueness: true, presence: true

  def version_token
    asset.file.checksum
  end

  def token_valid?
    !revoked_at? && expires_at > Time.current
  end

  def conflicts?(token)
    asset.locked? || version_token != token
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_default_expiration
    self.expires_at ||= Constants::ASSET_SYNC_TOKEN_EXPIRATION.from_now
  end
end
