# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::ResultsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    show: {
      id: 1,
      team_id: 1,
      project_id: 1,
      experiment_id: 1,
      task_id: 1
    },
    update: {
      id: 1,
      team_id: 1,
      project_id: 1,
      experiment_id: 1,
      task_id: 1
    },
    index: {
      id: 1,
      team_id: 1,
      project_id: 1,
      experiment_id: 1,
      task_id: 1
    }
  }, [:create, :destroy],
  :unauthorized


  describe 'permissions checking' do
    login_api_user

    include_context 'reference_project_structure', {
      team_role: :normal_user,
      result_text: true
    }

    let!(:result) { result_text.result }

    it_behaves_like "a controller action with permissions checking", :get, :show do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: my_module.id,
          id: result.id
        }
      }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::MANAGE] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: my_module.id,
          id: result.id
        }
      }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::MANAGE] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: my_module.id,
          id: result.id
        }
      }
    end
  end
end
