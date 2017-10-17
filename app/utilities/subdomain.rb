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

class WopiSubdomain
  def self.matches?(request)
    if ENV['WOPI_ENABLED'] == 'true'
      if ENV['WOPI_SUBDOMAIN']
        return (request.subdomain.present? &&
                request.subdomain == ENV['WOPI_SUBDOMAIN'])
      else
        return true
      end
    else
      return false
    end
  end
end
