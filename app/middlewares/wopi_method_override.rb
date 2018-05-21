# When WOPI performs calls onto SciNote WOPI subdomain REST endpoints
# Rack::MethodOverride MUST be omitted because it crashes the requests
# due to trying to parse body of the requests
class WopiMethodOverride
  def initialize(app)
    @app = app
  end

  def call(env)
    app = @app

    unless WopiSubdomain.matches?(ActionDispatch::Request.new(env))
      # Use the wrapped Rack::MethodOverride middleware
      app = Rack::MethodOverride.new(@app)
    end

    app.call(env)
  end
end
