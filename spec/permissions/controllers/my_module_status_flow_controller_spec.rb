# frozen_string_literal: true

require 'rails_helper'

describe MyModuleStatusFlowController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    show: { my_module_id: 1 }
  }, []

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user
    }

    it_behaves_like "a controller action with permissions checking", :get, :show do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id } }
    end
  end
end
