# frozen_string_literal: true

require 'rails_helper'

describe ResultCommentsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    index: { result_id: 1 },
    create: { result_id: 1 },
    update: { result_id: 1, id: 1 },
    destroy: { result_id: 1, id: 1 }
  }, []

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      result_text: true,
      result_comment: true,
    }

    it_behaves_like "a controller action with permissions checking", :get, :index do
      let(:testable) { project }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { result_id: result_text.result.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :create do
      let(:testable) { project }
      let(:permissions) { [MyModulePermissions::RESULTS_COMMENTS_CREATE] }
      let(:action_params) { { result_id: result_text.result.id, comment: { message: 'Test' } } }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update do
      let(:testable) { project }
      let(:permissions) { [MyModulePermissions::RESULTS_COMMENTS_MANAGE_OWN, MyModulePermissions::RESULTS_COMMENTS_MANAGE] }
      let(:action_params) { { result_id: result_text.result.id, id: result_text_comment.id, comment: { message: 'Test1' } } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :destroy do
      let(:testable) { project }
      let(:permissions) { [MyModulePermissions::RESULTS_COMMENTS_MANAGE_OWN, MyModulePermissions::RESULTS_COMMENTS_MANAGE] }
      let(:action_params) { { result_id: result_text.result.id, id: result_text_comment.id } }
    end
  end
end
