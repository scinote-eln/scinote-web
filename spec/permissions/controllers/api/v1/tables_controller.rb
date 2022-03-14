# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::TablesController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    show: {
      team_id: 1,
      project_id: 1,
      experiment_id: 1,
      task_id: 1,
      protocol_id: 1,
      step_id: 1,
      id: 1
    },
    update: {
      team_id: 1,
      project_id: 1,
      experiment_id: 1,
      task_id: 1,
      protocol_id: 1,
      step_id: 1,
      id: 1
    },
    create: {
      team_id: 1,
      project_id: 1,
      experiment_id: 1,
      task_id: 1,
      protocol_id: 1,
      step_id: 1,
    },
    destroy: {
      team_id: 1,
      project_id: 1,
      experiment_id: 1,
      task_id: 1,
      protocol_id: 1,
      step_id: 1,
      id: 1
    },
    index: {
      team_id: 1,
      project_id: 1,
      experiment_id: 1,
      task_id: 1,
      protocol_id: 1,
      step_id: 1
    }
  }, [],
  :unauthorized


  describe 'permissions checking' do
    login_api_user

    include_context 'reference_project_structure', {
      team_role: :normal_user,
      step: true,
      step_table: true
    }

    it_behaves_like "a controller action with permissions checking", :get, :show do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: my_module.id,
          protocol_id: step.protocol_id,
          step_id: step.id,
          id: step_table.id
        }
      }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::PROTOCOL_MANAGE] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: my_module.id,
          protocol_id: step.protocol_id,
          step_id: step.id,
          data: { attributes: { name: 'Test' }, type: 'tables' },
          id: step_table.id
        }
      }
    end

    it_behaves_like "a controller action with permissions checking", :delete, :destroy do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::PROTOCOL_MANAGE] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: my_module.id,
          protocol_id: step.protocol_id,
          step_id: step.id,
          id: step_table.id
        }
      }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::PROTOCOL_MANAGE] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: my_module.id,
          protocol_id: step.protocol_id,
          step_id: step.id,
          data: { attributes: { name: 'Test' }, type: 'tables' },
          id: step_table.id
        }
      }
    end
  end
end
