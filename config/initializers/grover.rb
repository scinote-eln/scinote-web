# frozen_string_literal: true

Grover.configure do |config|
  config.options = {
    cache: false,
    executable_path: ENV['CHROMIUM_PATH'] || '/usr/bin/chromium',
    launch_args: %w(--disable-dev-shm-usage --disable-gpu --no-sandbox),
    timeout: Constants::GROVER_TIMEOUT_MS
  }
end
