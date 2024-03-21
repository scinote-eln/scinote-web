# frozen_string_literal: true

require 'rails_helper'

describe ProjectsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    edit: { id: 1 },
    archive_group: { id: 1 },
    restore_group: { id: 1 },
    create: { id: 1 },
    update: { id: 1 },
    permissions: { id: 1 },
  }, [:current_folder, :set_breadcrumbs_items, :create_tag]

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      projects: 5,
      skip_my_module: true
    }

    it_behaves_like "a controller action with permissions checking", :put, :update do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::MANAGE] }
      let(:action_params) { { id: project.id, project: { name: 'Test' } } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :archive_group do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::MANAGE] }
      let(:action_params) { { projects_ids: [project.id] } }
      let(:custom_response_status) { :unprocessable_entity }
    end

    it_behaves_like "a controller action with permissions checking", :post, :restore_group do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::MANAGE] }
      let(:action_params) { { projects_ids: [project.id] } }
      let(:custom_response_status) { :unprocessable_entity }
    end
  end
end
