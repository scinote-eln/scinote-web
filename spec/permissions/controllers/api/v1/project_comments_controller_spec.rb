# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::ProjectCommentsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    index: {
      team_id: 1,
      project_id: 1,
    },
    show: {
      team_id: 1,
      project_id: 1,
      id: 1
    }
  }, [],
  :unauthorized


  describe 'permissions checking' do
    login_api_user

    include_context 'reference_project_structure', {
      team_role: :normal_user,
      project_comment: true
    }

    it_behaves_like "a controller action with permissions checking", :get, :index do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::COMMENTS_READ] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id
        }
      }
    end

    it_behaves_like "a controller action with permissions checking", :get, :show do
      let(:testable) { experiment }
      let(:permissions) { [ProjectPermissions::COMMENTS_READ] }
      let(:action_params) {
        {
          team_id: team.id,
          project_id: project.id,
          id: project_comment.id
        }
      }
    end
  end
end
