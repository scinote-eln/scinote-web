# frozen_string_literal: true

require 'rails_helper'

describe MyModuleCommentsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    index: { my_module_id: 1, id: 1 },
    create: { my_module_id: 1, id: 1 },
    update: { my_module_id: 1, id: 1 },
    destroy: { my_module_id: 1, id: 1 }
  }, []

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      my_module_comment: true
    }

    it_behaves_like "a controller action with permissions checking", :get, :index do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::COMMENTS_CREATE] }
      let(:action_params) { { my_module_id: my_module.id, comment: { message: 'Test' } } }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::COMMENTS_MANAGE, MyModulePermissions::COMMENTS_MANAGE_OWN] }
      let(:action_params) { { my_module_id: my_module.id, id: my_module_comment.id, comment: { message: 'Test1' } } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :destroy do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::COMMENTS_MANAGE, MyModulePermissions::COMMENTS_MANAGE_OWN] }
      let(:action_params) { { my_module_id: my_module.id, id: my_module_comment.id } }
    end
  end
end
