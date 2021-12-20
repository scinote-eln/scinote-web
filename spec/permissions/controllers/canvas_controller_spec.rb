# frozen_string_literal: true

require 'rails_helper'

describe CanvasController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    edit: { id: 1 },
    full_zoom: { id: 1 },
    medium_zoom: { id: 1 },
    small_zoom: { id: 1 },
    update: { id: 1 }
  }, []

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user,
      my_modules: 3
    }

    it_behaves_like "a controller action with permissions checking", :get, :edit do
      let(:testable) { project }
      let(:permissions) { [ExperimentPermissions::MANAGE] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :full_zoom do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::READ] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :medium_zoom do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::READ] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :small_zoom do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::READ] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :update do
      let(:testable) { experiment }
      let(:permissions) { [ExperimentPermissions::MANAGE] }
      let(:action_params) { { id: experiment.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :update do
      let(:testable) { my_modules.first }
      let(:permissions) { [MyModulePermissions::MANAGE] }
      let(:action_params) { { id: experiment.id, remove: "#{my_modules.first.id},#{my_modules.second.id}" } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :update do
      let(:testable) { my_modules.first }
      let(:permissions) { [MyModulePermissions::MANAGE] }
      let(:action_params) { { id: experiment.id, rename: "{\"#{my_modules.first.id}\": \"Test\"}" } }
    end
  end
end
