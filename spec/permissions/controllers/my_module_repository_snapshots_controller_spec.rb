# frozen_string_literal: true

require 'rails_helper'

describe MyModuleRepositorySnapshotsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    index_dt: { my_module_id: 1, id: 1 },
    create: { my_module_id: 1, repository_id: 1 },
    status: { my_module_id: 1, id: 1 },
    show: { my_module_id: 1, id: 1 },
    destroy: { my_module_id: 1, id: 1 },
    full_view_table: { my_module_id: 1, id: 1 },
    full_view_sidebar: { my_module_id: 1, repository_id: 1 },
    select: { my_module_id: 1 },
    export_repository_snapshot: { my_module_id: 1, id: 1 }
  }, []

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user
    }

    let(:repository) { create :repository, team: team, created_by: user }
    let (:repository_row) { create :repository_row, repository: repository, created_by: user, last_modified_by: user }
    let (:repository_snapshot) { create :repository_snapshot, original_repository: repository, my_module: my_module }

    it_behaves_like "a controller action with permissions checking", :get, :index_dt do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: repository_snapshot.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::REPOSITORY_ROWS_MANAGE] }
      let(:action_params) { { my_module_id: my_module.id, repository_id: repository.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :status do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: repository_snapshot.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :show do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: repository_snapshot.id } }
    end

    it_behaves_like "a controller action with permissions checking", :delete, :destroy do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::REPOSITORY_ROWS_MANAGE] }
      let(:action_params) { { my_module_id: my_module.id, id: repository_snapshot.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :full_view_table do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: repository_snapshot.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :full_view_sidebar do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, repository_id: repository.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :select do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::REPOSITORY_ROWS_MANAGE] }
      let(:action_params) { { my_module_id: my_module.id, repository_snapshot_id: repository_snapshot.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :export_repository_snapshot do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id, id: repository_snapshot.id } }
    end
  end
end
