# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'a controller action with permissions checking' do |verb, action|
  describe 'controller action' do
    context 'user without permissions' do
      it "returns forbidden response for action :#{action}" do
        testable_role = testable.user_assignments.find_by(user: user).user_role
        testable_role.update_column(:permissions, testable_role.permissions - permissions)
        send(verb, action, params: defined?(action_params) ? action_params : {})
        expect(response).to have_http_status(defined?(custom_response_status) ? custom_response_status : :forbidden)
      end
    end
  end
end
