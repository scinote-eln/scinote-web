# frozen_string_literal: true

require 'rails_helper'

describe MyModuleRepositoriesController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    index_dt: { my_module_id: 1, id: 1 },
    create: { my_module_id: 1, id: 1, my_module_tag: { tag_id: 1, my_module_id: 1 } },
    update: { my_module_id: 1, id: 1 },
    update_repository_records_modal: { my_module_id: 1, id: 1 },
    assign_repository_records_modal: { my_module_id: 1, id: 1 },
    repositories_list_html: { my_module_id: 1 },
    full_view_table: { my_module_id: 1, id: 1 },
    repositories_dropdown_list: { my_module_id: 1 },
    export_repository: { my_module_id: 1, id: 1 },
    consume_modal: { my_module_id: 1, id: 1 },
    update_consumption: { my_module_id: 1, id: 1 }
  }, []

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure'

    let(:repository) { create :repository, team: team, created_by: user }
    let (:repository_row) { create :repository_row, repository: repository, created_by: user, last_modified_by: user }


    it_behaves_like "a controller action with permissions checking", :get, :index_dt do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: repository.id } }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::REPOSITORY_ROWS_ASSIGN] }
      let(:action_params) { { my_module_id: my_module.id, id: repository.id, rows_to_assign: [repository_row.id] } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :update_repository_records_modal do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: repository.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :assign_repository_records_modal do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: repository.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :repositories_list_html do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :full_view_table do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: repository.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :repositories_dropdown_list do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :export_repository do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: repository.id } }
    end
  end
end
