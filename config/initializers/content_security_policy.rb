# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy
require 'uri'

def valid_url?(url)
  uri = URI.parse(url)
  return false unless %w(http https ws wss).include?(uri.scheme)
  return false if uri.host.nil? || uri.host.empty? || uri.host.start_with?('.')

  true
rescue URI::InvalidURIError
  false
end

def wepacker_port
  uri = URI.parse("http://#{Webpacker.dev_server.host_with_port}")
  uri.port
end

def host_to_url(protocol, str, port)
  "#{protocol}://#{str}:#{port}" if str.present? && protocol.present? && port.present?
end

hosts = Rails.application.config.hosts

external_services = %w(https://www.protocols.io/)

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.base_uri    :self, *external_services
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, :unsafe_eval
  policy.style_src   :self, :https, :unsafe_inline

  if Rails.env.development?
    hosts_urls = %w(ws http).flat_map do |protocol|
      hosts.map { |host| host_to_url(protocol, host, wepacker_port)}
    end.select { |url| valid_url?(url)}


    policy.connect_src :self, :data, *hosts_urls, "http://127.0.0.1:9100/available"
  else
    policy.connect_src :self, :data, "http://127.0.0.1:9100/available"
  end

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(style-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
Rails.application.config.content_security_policy_report_only = true
