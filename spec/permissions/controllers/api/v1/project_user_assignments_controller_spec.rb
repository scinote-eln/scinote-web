# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::ProjectUserAssignmentsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    index: {
      team_id: 1,
      project_id: 1
    },
    show: {
      team_id: 1,
      project_id: 1,
      id: 1
    },
    create: {
      team_id: 1,
      project_id: 1
    },
    update: {
      team_id: 1,
      project_id: 1,
      id: 1
    },
    destroy: {
      team_id: 1,
      project_id: 1,
      id: 1
    }
  }, [],
  :unauthorized


  describe 'permissions checking' do
    login_api_user

    include_context 'reference_project_structure', {
      team_role: :normal_user
    }

    it_behaves_like "a controller action with permissions checking", :get, :index do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::USERS_READ, ProjectPermissions::USERS_MANAGE] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
        }
      }
    end

    it_behaves_like "a controller action with permissions checking", :get, :show do
      let(:user_assignment) { UserAssignment.find_by(assignable: project) }
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::USERS_READ, ProjectPermissions::USERS_MANAGE] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          id: user_assignment.id
        }
      }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update do
      let(:user_assignment) { UserAssignment.find_by(assignable: project) }
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::USERS_MANAGE] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          id: user_assignment.id
        }
      }
    end

    it_behaves_like "a controller action with permissions checking", :delete, :destroy do
      let(:user_assignment) { UserAssignment.find_by(assignable: project) }
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::USERS_MANAGE] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          id: user_assignment.id
        }
      }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:user_assignment) { UserAssignment.find_by(assignable: project) }
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::USERS_MANAGE] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          id: user_assignment.id,
          data: {
            type: "project_user_assignments",
            attributes: {
              user_id: 1,
              role_id: 1
            }
          }
        }
      }
    end
  end
end
