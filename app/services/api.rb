module Api
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :core_api_sign_alg
    attr_accessor :core_api_token_ttl
    attr_accessor :core_api_token_iss
    attr_accessor :azure_ad_apps
    attr_accessor :core_api_v1_preview
    attr_accessor :core_api_rate_limit

    def initialize
      @core_api_sign_alg = 'HS256'
      @core_api_token_ttl = 30.minutes
      @core_api_token_iss = 'SciNote'
      @azure_ad_apps = {}
      @core_api_v1_preview = false
      @core_api_rate_limit = 1000
    end
  end
end
