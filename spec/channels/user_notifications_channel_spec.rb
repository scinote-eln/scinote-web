require 'rails_helper'

RSpec.describe UserNotificationsChannel, type: :channel do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  # This matches your Connection#find_verified_user implementation
  # (env['warden'].user must return the current user)
  let(:warden) { instance_double("Warden::Proxy") }

  before do
    allow(warden).to receive(:user).and_return(user)

    stub_connection current_user: user, env: { "warden" => warden }
  end

  it "successfully subscribes for an authenticated user and streams for that user" do
    subscribe
    expect(subscription).to be_confirmed

    # stream_for(current_user) uses this naming convention internally
    expect(subscription).to have_stream_for(user)
  end

  it "delivers broadcasts only to the authenticated user's stream" do
    subscribe
    expect(subscription).to have_stream_for(user)
    expect(subscription).not_to have_stream_for(other_user)

    expect do
      UserNotificationsChannel.broadcast_to(user, { 'unseen_counter' => 1 })
    end.to have_broadcasted_to(user).from_channel(UserNotificationsChannel).with('unseen_counter' => 1)

    expect do
      UserNotificationsChannel.broadcast_to(user, { 'unseen_counter' => '1' })
    end.not_to have_broadcasted_to(other_user)

    # Show that a broadcast to a different user is not for this subscription
    expect do
      UserNotificationsChannel.broadcast_to(other_user, { 'unseen_counter' => '1' })
    end.not_to have_broadcasted_to(user)
  end
end
