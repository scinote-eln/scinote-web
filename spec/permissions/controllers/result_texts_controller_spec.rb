# frozen_string_literal: true

require 'rails_helper'

describe ResultTextsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    edit: { id: 1 },
    update: { id: 1 },
    download: { id: 1 }
  }

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      result_text: true
    }

    it_behaves_like "a controller action with permissions checking", :get, :edit do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::RESULTS_MANAGE] }
      let(:action_params) { { id:result_text.id, format: :json } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :download do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id:result_text.id } }
    end

    it_behaves_like "a controller action with permissions checking", :patch, :update do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::RESULTS_MANAGE] }
      let(:action_params) { { id:result_text.id, result: { result_text_attributes: { text: 'test1' } } } }
    end
  end
end
