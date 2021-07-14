# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :password, :image, /^avatar$/, :passw, :secret, :token, :_key, :crypt, :salt,
  :certificate, :otp, :otp_recovery_codes, :otp_secret, :ssn
]
