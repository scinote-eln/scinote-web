# frozen_string_literal: true

class WopiApp < ApplicationRecord
  belongs_to :wopi_discovery, foreign_key: 'wopi_discovery_id', class_name: 'WopiDiscovery'
  has_many :wopi_actions, class_name: 'WopiAction', foreign_key: 'wopi_app_id', dependent: :destroy

  validates :name, :icon, :wopi_discovery, presence: true
end
