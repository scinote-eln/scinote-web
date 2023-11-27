# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'a controller with authentication' do |actions_with_params, actions_to_skip, custom_response|
  let (:protected_actions) { described_class.instance_methods(false) - (actions_to_skip || []) }

  describe 'controller actions' do
    context 'unauthenticated user' do
      it "returns #{custom_response || :forbidden} response for all actions" do
        sign_out :user
        actions_with_params ||= {}
        protected_actions.each do |action|
          params = actions_with_params[action]
          get action, params: params
          expect(response).to have_http_status(custom_response || :forbidden).or redirect_to('/users/sign_in')
        end
      rescue ActionController::UrlGenerationError => e
        warn "Warning: #{e}"
      end
    end
  end
end
