# frozen_string_literal: true

require 'rails_helper'

describe ProjectCommentsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    index: { project_id: 1, id: 1 },
    create: { project_id: 1, id: 1 },
    update: { project_id: 1, id: 1 },
    destroy: { project_id: 1, id: 1 }
  }, []

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      project_comment: true,
      skip_my_module: true
    }

    it_behaves_like "a controller action with permissions checking", :get, :index do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::READ] }
      let(:action_params) { { project_id: project.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::COMMENTS_CREATE] }
      let(:action_params) { { project_id: project.id, comment: { message: 'Test' } } }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::COMMENTS_MANAGE, ProjectPermissions::COMMENTS_MANAGE_OWN] }
      let(:action_params) { { project_id: project.id, id: project_comment.id, comment: { message: 'Test1' } } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :destroy do
      let(:testable) { project }
      let(:permissions) { [ProjectPermissions::COMMENTS_MANAGE, ProjectPermissions::COMMENTS_MANAGE_OWN] }
      let(:action_params) { { project_id: project.id, id: project_comment.id } }
    end
  end
end
