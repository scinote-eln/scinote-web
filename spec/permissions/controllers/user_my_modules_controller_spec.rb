# frozen_string_literal: true

require 'rails_helper'

describe UserMyModulesController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    designated_users: { my_module_id: 1 },
    index: { my_module_id: 1 },
    index_edit: { my_module_id: 1 },
    search: { my_module_id: 1, id: 1 },
    create: { my_module_id: 1 },
    destroy: { my_module_id: 1, id: 1 }
  }, []

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user
    }

    it_behaves_like "a controller action with permissions checking", :get, :designated_users do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :index do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :index_edit do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :search do
      let(:testable) { my_module }
      let(:user_my_module) { UserMyModule.create!(my_module: my_module, user: user) }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: user_my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::DESIGNATED_USERS_MANAGE] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :destroy do
      let(:testable) { my_module }
      let(:user_my_module) { UserMyModule.create!(my_module: my_module, user: user) }
      let(:permissions) { [MyModulePermissions::DESIGNATED_USERS_MANAGE] }
      let(:action_params) { { my_module_id: my_module.id, id: user_my_module.id } }
    end
  end
end
