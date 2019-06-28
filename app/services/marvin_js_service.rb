# frozen_string_literal: true

class MarvinJsService
  def self.url
    ENV['MARVINJS_URL']
  end

  def self.enabled?
    !ENV['MARVINJS_URL'].nil? || !ENV['MARVINJS_API_KEY'].nil?
  end
end
