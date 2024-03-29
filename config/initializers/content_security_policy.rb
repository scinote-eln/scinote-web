# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

ActiveSupport::Reloader.to_prepare do
  Rails.application.config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.base_uri    :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, :unsafe_eval, *Extends::EXTERNAL_SERVICES
    policy.style_src   :self, :https, :unsafe_inline, :data
    policy.connect_src :self, :data, *Extends::EXTERNAL_SERVICES

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end
end

# https://discuss.rubyonrails.org/t/turbolinks-broken-by-default-with-a-secure-csp/74790
Rails.application.config.content_security_policy_nonce_generator = -> (request) do
  # use the same csp nonce for turbolinks requests
  if request.env['HTTP_TURBOLINKS_REFERRER'].present?
    request.env['HTTP_X_TURBOLINKS_NONCE']
  else
    return request.session.id.to_s if request&.session&.id.present?

    SecureRandom.base64(16)
  end
end

# Set the nonce only to specific directives
Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true

# Whitelist AWS buckets
Rails.application.configure do
  config.after_initialize do
    if ActiveStorage::Blob.service.name == :amazon
      Extends::EXTERNAL_SERVICES += [ActiveStorage::Blob.service.bucket.url]
      if ActiveStorage::Blob.service.staging_bucket.present?
        Extends::EXTERNAL_SERVICES += [ActiveStorage::Blob.service.staging_bucket.url]
      end
      Rails.application.config.content_security_policy.connect_src :self, :data, *Extends::EXTERNAL_SERVICES
    end
  end
end
