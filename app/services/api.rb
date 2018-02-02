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

    def initialize
      @core_api_sign_alg = 'HS256'
      @core_api_token_ttl = 30.minutes
      @core_api_token_iss = 'SciNote'
    end
  end
end
