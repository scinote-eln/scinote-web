# frozen_string_literal: true

require 'rails_helper'

describe Rack::SetWopiBinaryRequestType do
  let(:seen_env) { {} }
  let(:app) do
    lambda do |env|
      seen_env.replace(env)
      [200, {}, ['ok']]
    end
  end
  let(:middleware) { described_class.new(app) }

  def call(method, path, content_type: 'application/json')
    middleware.call(Rack::MockRequest.env_for(path, method: method, 'CONTENT_TYPE' => content_type))
  end

  it 'forces octet-stream for POST to the WOPI contents endpoint and calls the app' do
    status, _headers, body = call('POST', '/wopi/files/12/contents')
    expect(seen_env['CONTENT_TYPE']).to eq 'application/octet-stream'
    expect([status, body]).to eq [200, ['ok']]
  end

  it 'keeps the content type for other methods' do
    call('GET', '/wopi/files/12/contents')
    expect(seen_env['CONTENT_TYPE']).to eq 'application/json'
  end

  it 'keeps the content type for other paths' do
    call('POST', '/wopi/files/12')
    expect(seen_env['CONTENT_TYPE']).to eq 'application/json'
  end

  it 'does not match non-numeric file ids or trailing segments' do
    call('POST', '/wopi/files/abc/contents')
    expect(seen_env['CONTENT_TYPE']).to eq 'application/json'
    call('POST', '/wopi/files/12/contents/extra')
    expect(seen_env['CONTENT_TYPE']).to eq 'application/json'
  end
end
