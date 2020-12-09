# frozen_string_literal: true

return unless Rails.env.production?

return if Rails.configuration.x.core_api_rate_limit.zero?

Rack::Attack.throttle('api requests by ip',
                      limit: Rails.configuration.x.core_api_rate_limit,
                      period: 60) do |request|
  request.ip if request.path.match?(%r{^\/api\/})
end

Rack::Attack.throttled_response = lambda do |env|
  match_data = env['rack.attack.match_data']
  now = match_data[:epoch_time]

  headers = {
    'RateLimit-Limit' => match_data[:limit].to_s,
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset' => (
      now + (match_data[:period] - now % match_data[:period])
    ).to_s
  }

  [429, headers, ["Throttled\n"]]
end
