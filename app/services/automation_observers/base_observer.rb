# frozen_string_literal: true

module AutomationObservers
  class BaseObserver
    def self.on_create(object, user); end

    def self.on_update(object, user); end
  end
end
