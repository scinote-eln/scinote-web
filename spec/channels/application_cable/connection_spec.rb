# frozen_string_literal: true

require 'rails_helper'

describe ApplicationCable::Connection do
  include ActionCable::Connection::TestCase::Behavior

  tests ApplicationCable::Connection

  let(:user) { create(:user) }

  def warden_double(returning)
    warden = instance_double(Warden::Proxy)
    allow(warden).to receive(:user).with(:user).and_return(returning)
    warden
  end

  it 'identifies the connection by the warden authenticated user' do
    connect '/cable', env: { 'warden' => warden_double(user) }

    expect(connection.current_user).to eq user
  end

  it 'rejects the connection when warden has no user' do
    expect { connect '/cable', env: { 'warden' => warden_double(nil) } }
      .to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
  end

  it 'rejects the connection when warden throws :warden (authentication failure)' do
    warden = instance_double(Warden::Proxy)
    allow(warden).to receive(:user).with(:user) { throw :warden }

    expect { connect '/cable', env: { 'warden' => warden } }
      .to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
  end
end
