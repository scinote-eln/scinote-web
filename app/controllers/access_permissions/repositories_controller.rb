# frozen_string_literal: true

module AccessPermissions
  class RepositoriesController < BaseController
    private

    def set_model
      @model = Repository.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @model
    end

    def check_manage_permissions
      render_403 unless can_manage_repository_users?(@model)
    end

    def check_read_permissions
      render_403 unless can_manage_repository_users?(@model) || can_read_repository?(@model)
    end
  end
end
