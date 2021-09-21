# frozen_string_literal: true

require 'rails_helper'

describe ResultTablesController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    new: { my_module_id: 1 },
    create: { my_module_id: 1 },
    edit: { id: 1 },
    update: { id: 1 },
    download: { id: 1 }
  }

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      result_table: true
    }

    it_behaves_like "a controller action with permissions checking", :get, :new do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::RESULTS_MANAGE] }
      let(:action_params) { { my_module_id: my_module.id, format: :json } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::RESULTS_MANAGE] }
      let(:action_params) {
        { my_module_id: my_module.id, result: { name: 'test', table_attributes: { content: 'test' } } }
      }
    end

    it_behaves_like "a controller action with permissions checking", :get, :edit do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::RESULTS_MANAGE] }
      let(:action_params) { { id: result_table.id, format: :json } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :download do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id: result_table.id } }
    end

    it_behaves_like "a controller action with permissions checking", :patch, :update do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::RESULTS_MANAGE] }
      let(:action_params) { { id: result_table.id, result: { table_attributes: { content: 'test1' } } } }
    end
  end
end
