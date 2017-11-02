Devise::Async.enabled = true
Devise::Async.backend = :delayed_job
Devise::Async.queue = :devise_email
# Devise::Async.priority = 10