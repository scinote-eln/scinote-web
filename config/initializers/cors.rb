# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

<<<<<<< HEAD
if ENV['SCINOTE_PWA_DOMAIN_NAME'].present?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins ENV['SCINOTE_PWA_DOMAIN_NAME']

      resource '/oauth/token',
               headers: :any,
               methods: %i(post)

      resource '/rails/active_storage/*',
               headers: :any,
               methods: %i(get post options head)

      resource '/api/*',
               headers: :any,
               methods: %i(get post put patch delete options head)
    end
  end
end
=======
# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins 'example.com'
#
#     resource '*',
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head]
#   end
# end
>>>>>>> Initial commit of 1.17.2 merge
