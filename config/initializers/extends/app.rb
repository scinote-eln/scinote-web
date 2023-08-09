# frozen_string_literal: true

require 'scinote/app'

Scinote::App.setup do |config|
  config.pendo_enabled = ENV['PENDO_ENABLED'] == 'true'
  config.pendo_id = ENV.fetch('PENDO_ID', '') if config.pendo_enabled
end
