# frozen_string_literal: true

require 'rails_helper'

class TokenAuthenticatedController
  attr_accessor :token, :current_user

  include TokenAuthentication

  def request
    OpenStruct.new(
      headers: { 'Authorization' => "Bearer #{@token}" }
    )
  end
end

describe TokenAuthentication do
  let(:test_controller_instance) { TokenAuthenticatedController.new }

  let(:user) { create :user }
  let(:access_token) {
    user.access_tokens.create(
      expires_in: 7500
    )
  }

  describe '#authenticate_request' do
    it "rejects revoked token" do
      test_controller_instance.token = access_token.token
      test_controller_instance.current_user = user

      access_token.revoke
      expect { test_controller_instance.send(:authenticate_request!) }.to raise_error(JWT::VerificationError)
    end
  end
end
