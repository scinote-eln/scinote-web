# frozen_string_literal: true

if ENV['DD_TRACE_ENABLED'] == 'true'
  require 'datadog/auto_instrument'

  Datadog.configure do |config|
    config.tracing.enabled = ENV['DD_TRACE_ENABLED'] == 'true'
  end
end
