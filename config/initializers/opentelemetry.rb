require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/rails'
require 'opentelemetry-propagator-xray'

OpenTelemetry::SDK.configure do |config|
  # The X-Ray ID Generator generates spans with X-Ray backend compliant IDs
  config.id_generator = OpenTelemetry::Propagator::XRay::IDGenerator

  # The X-Ray Propagator injects the X-Ray Tracing Header into downstream calls
  config.propagators = [OpenTelemetry::Propagator::XRay::TextMapPropagator.new]

  config.use_all # enables all instrumentation!
end
