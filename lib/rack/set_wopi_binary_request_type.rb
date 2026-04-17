# frozen_string_literal: true

module Rack
  class SetWopiBinaryRequestType
    def initialize(app)
      @app = app
    end

    def call(env)
      if env['REQUEST_METHOD'] == 'POST' && %r{\A/wopi/files/\d+/contents\z}.match?(env['PATH_INFO'])
        # prevent Rails from trying to parse body into request_parameters
        env['CONTENT_TYPE'] = 'application/octet-stream'
      end

      @app.call(env)
    end
  end
end
