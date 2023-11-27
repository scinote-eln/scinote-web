# frozen_string_literal: true

require 'rails_helper'

describe ResultsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    index: {
      my_module_id: 1
    },
    create: {
      my_module_id: 1
    },
    destroy: {
      my_module_id: 1,
      id: 1
    },
    assets: {
      my_module_id: 1,
      id: 1
    },
    update: {
      my_module_id: 1,
      id: 1
    },
    elements: {
      my_module_id: 1,
      id: 1
    },
    archive: {
      my_module_id: 1,
      id: 1
    },
    upload_attachment: {
      my_module_id: 1,
      id: 1
    },
    update_view_state: {
      my_module_id: 1,
      id: 1
    },
    update_asset_view_mode: {
      my_module_id: 1,
      id: 1
    },
    restore: {
      my_module_id: 1,
      id: 1
    },
    duplicate: {
      my_module_id: 1,
      id: 1
    }
  }, [:set_breadcrumbs_items]

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      result_text: true

    }
    let!(:result) { result_text.result }

    before do
      result.archive!(user)
    end

    it_behaves_like "a controller action with permissions checking", :delete, :destroy do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::RESULTS_DELETE_ARCHIVED] }
      let(:action_params) { { my_module_id: my_module.id, id: result.id } }
    end
  end
end
