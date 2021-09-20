# frozen_string_literal: true

require 'rails_helper'

describe ResultsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    destroy: { id: 1 }
  }

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      result_text: true

    }
    let!(:result) { result_text.result }

    before do
      result.archive!(user)
    end

    it_behaves_like "a controller action with permissions checking", :delete, :destroy do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::RESULTS_DELETE_ARCHIVED] }
      let(:action_params) { { id: result.id } }
    end
  end
end
