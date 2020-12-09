# frozen_string_literal: true

class WopiAction < ApplicationRecord
  belongs_to :wopi_app, foreign_key: 'wopi_app_id', class_name: 'WopiApp'

  validates :action, :extension, :urlsrc, :wopi_app, presence: true
end
