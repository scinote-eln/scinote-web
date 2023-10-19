# frozen_string_literal: true

require 'rails_helper'

describe ProjectsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    sidebar: { id: 1 },
    edit: { id: 1 },
    update: { id: 1 },
    show: { id: 1 },
    experiments_cards: { id: 1 },
    notifications: { id: 1 },
    permissions: { id: 1 },
    actions_dropdown: { id: 1 },
    view_type: { id: 1 }
  }, [:current_folder, :set_breadcrumbs_items, :create_tag]

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      projects: 5,
      skip_my_module: true
    }

    it_behaves_like "a controller action with permissions checking", :get, :sidebar do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::READ] }
      let(:action_params) { { id: project.id } }
    end

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

    it_behaves_like "a controller action with permissions checking", :get, :show do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::READ] }
      let(:action_params) { { id: project.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :experiments_cards do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::READ] }
      let(:action_params) { { id: project.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :notifications do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::READ] }
      let(:action_params) { { id: project.id } }
    end

    it_behaves_like "a controller action with permissions checking", :put, :view_type do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::READ] }
      let(:action_params) { { id: project.id } }
    end
  end
end
