# frozen_string_literal: true

if ENV['DD_TRACE_ENABLED'] == 'true'
  Datadog.configure do |config|
    config.tracing.enabled = true
    config.tracing.instrument :action_cable, enabled: false
    config.tracing.instrument :action_mailer, enabled: false
    config.tracing.instrument :pg, enabled: false
  end
end
