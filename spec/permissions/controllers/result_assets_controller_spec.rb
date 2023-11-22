# frozen_string_literal: true

require 'rails_helper'

describe ResultAssetsController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    edit: { id: 1 },
    update: { id: 1 }
  }

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      result_asset: true
    }

    it_behaves_like "a controller action with permissions checking", :get, :edit do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::RESULTS_MANAGE] }
      let(:action_params) { { id: result_asset.id, format: :json } }
    end

    it_behaves_like "a controller action with permissions checking", :patch, :update do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::RESULTS_MANAGE] }
      let(:action_params) { { id: result_asset.id, result: { asset_attributes: 'new_signed_blob_id' } } }
    end
  end
end
