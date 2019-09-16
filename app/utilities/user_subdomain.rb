class UserSubdomain
  def self.matches?(request)
    if ENV['USER_SUBDOMAIN']
      return (request.subdomain.present? &&
              request.subdomain == ENV['USER_SUBDOMAIN'])
    else
      return true
    end
  end
end
