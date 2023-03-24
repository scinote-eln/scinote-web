# frozen_string_literal: true

module Doorkeeper
  class AccessTokensController < ApplicationController
    before_action :find_token

    def revoke
      @token.revoke
    end

    private

    def find_token
      @token = current_user.access_tokens.find(params[:id])
    end
  end
end
