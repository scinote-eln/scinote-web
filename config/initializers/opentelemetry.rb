# frozen_string_literal: true

if ENV['OTEL_ENABLED'] == 'true'
  require 'opentelemetry/sdk'
  require 'opentelemetry/instrumentation/rails'

  OpenTelemetry::SDK.configure do |config|
    if ENV['OTEL_XRAY_ENABLED'] == 'true'
      require 'opentelemetry-propagator-xray'
      # The X-Ray ID Generator generates spans with X-Ray backend compliant IDs
      config.id_generator = OpenTelemetry::Propagator::XRay::IDGenerator
      # The X-Ray Propagator injects the X-Ray Tracing Header into downstream calls
      config.propagators = [OpenTelemetry::Propagator::XRay::TextMapPropagator.new]
    end

    config.use_all # enables all instrumentation!
  end
end
