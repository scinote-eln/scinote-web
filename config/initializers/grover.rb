# frozen_string_literal: true

Grover.configure do |config|
  config.options = {
    cache: false,
    executable_path: ENV['CHROMIUM_PATH'] || 'chromium',
    launch_args: ['--disable-dev-shm-usage'],
    timeout: Constants::GROVER_TIMEOUT_MS
  }
end
