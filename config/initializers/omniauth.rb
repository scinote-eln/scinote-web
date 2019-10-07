require 'omniauth-linkedin-oauth2'

if Rails.configuration.x.enable_user_registration
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :linkedin, ENV['LINKEDIN_KEY'], ENV['LINKEDIN_SECRET']
  end
end
