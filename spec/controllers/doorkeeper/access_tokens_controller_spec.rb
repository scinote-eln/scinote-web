# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::AccessTokensController, type: :controller do
  login_user

  let!(:access_token) do
    subject.current_user.access_tokens.create(expires_in: 7500)
  end

  describe 'POST revoke' do
    let(:params) do
      {
        id: access_token.id
      }
    end

    let(:action) do
      put :revoke, params: params
    end

    it 'revokes the access token' do
      action
      expect(access_token.reload.revoked_at).to_not be_nil
    end
  end
end
