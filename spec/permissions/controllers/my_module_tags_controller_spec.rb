# frozen_string_literal: true

require 'rails_helper'

describe MyModuleTagsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    index_edit: { my_module_id: 1 },
    index: { my_module_id: 1 },
    canvas_index: { id: 1 },
    create: { my_module_id: 1 },
    destroy: { my_module_id: 1, id: 1 },
    search_tags: { my_module_id: 1 },
    destroy_by_tag_id: { my_module_id: 1, id: 1 }
  }, []

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      tag: true
    }

    it_behaves_like "a controller action with permissions checking", :get, :index_edit do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :index do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :canvas_index do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::READ] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::TAGS_MANAGE] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :destroy do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::TAGS_MANAGE] }
      let(:action_params) { { my_module_id: my_module.id, id: tag.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :search_tags do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { my_module_id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :destroy_by_tag_id do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::TAGS_MANAGE] }
      let(:action_params) { { my_module_id: my_module.id, id: tag.id } }
    end
  end
end
