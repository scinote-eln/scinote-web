# frozen_string_literal: true

class WopiDiscovery < ApplicationRecord
  require 'base64'

  has_many :wopi_apps,
           class_name: 'WopiApp',
           foreign_key: 'wopi_discovery_id',
           dependent: :destroy
  validates :expires,
            :proof_key_mod,
            :proof_key_exp,
            :proof_key_old_mod,
            :proof_key_old_exp,
            presence: true
end
