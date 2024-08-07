# frozen_string_literal: true

Grover.configure do |config|
  config.options = {
    cache: false,
    executable_path: './bin/chromium',
    launch_args: %w(--disable-gpu --no-sandbox),
    timeout: Constants::GROVER_TIMEOUT_MS
  }
end
