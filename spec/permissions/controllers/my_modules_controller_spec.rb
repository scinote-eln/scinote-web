# frozen_string_literal: true

require 'rails_helper'

describe MyModulesController, type: :controller do
  include PermissionExtends

  it_behaves_like "a controller with authentication", {
    show: { id: 1 },
    description: { id: 1 },
    status_state: { id: 1 },
    activities: { id: 1 },
    activities_tab: { id: 1 },
    due_date: { id: 1 },
    update: { id: 1 },
    update_description: { id: 1 },
    update_protocol_description: { id: 1 },
    protocols: { id: 1 },
    protocol: { id: 1 },
    update_protocol: { id: 1 },
    provisioning_status: { id: 1 },
    actions_dropdown: { id: 1 },
    new: { id: 1, experiment_id: 1 },
    create: { id: 1, experiment_id: 1 },
    permissions: { id: 1 },
    archive: { id: 1 },
    restore_group: { id: 1 },
    update_state: { id: 1 },
    canvas_dropdown_menu: { id: 1 }
  }, %i(set_breadcrumbs_items)

  login_user

  describe 'permissions checking' do
    include_context 'reference_project_structure', {
      team_role: :normal_user
    }

    it_behaves_like "a controller action with permissions checking", :get, :show do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :description do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :status_state do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :activities do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :activities_tab do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :due_date do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::MANAGE] }
      let(:action_params) { { id: my_module.id, my_module: { name: 'Test1' } } }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update_description do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::MANAGE] }
      let(:action_params) { { id: my_module.id, my_module: { description: 'Test description' } } }
    end

    it_behaves_like "a controller action with permissions checking", :put, :update_protocol_description do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::MANAGE] }
      let(:action_params) { { id: my_module.id, protocol: { description: 'Test description' } } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :protocols do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :get, :archive do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id: my_module.id } }
    end

    it_behaves_like "a controller action with permissions checking", :post, :update_state do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::UPDATE_STATUS] }
      let(:action_params) { { id: my_module.id, my_module: { status_id: my_module.my_module_status_id } } }
    end


    describe 'POST restore_group' do
      let(:action) { post :restore_group, params: { id: my_module.experiment.id, my_modules_ids: [my_module.id] } }

      context 'when task is not restored' do
        context 'when user does not have permissions for the task' do
          it 'task is not restored' do
            my_module.archive!(user)
            testable_role = my_module.user_assignments.find_by(user: user ).user_role
            testable_role.update_column(:permissions, testable_role.permissions - [MyModulePermissions::MANAGE])
            action
            expect(response).to have_http_status(302)
            expect(my_module.reload.archived?).to be_truthy
          end
        end
      end
    end

    it_behaves_like "a controller action with permissions checking", :get, :canvas_dropdown_menu do
      let(:testable) { my_module }
      let(:permissions) { [MyModulePermissions::READ] }
      let(:action_params) { { id: my_module.id } }
    end
  end
end
