# frozen_string_literal: true

module AccessPermissions
  class FormsController < BaseController
    def destroy
      # prevent deletion of last manually assigned user that can manage users
      raise ActiveRecord::RecordInvalid if params[:user_id].present? && @@assignment.last_with_permission?(FormPermissions::USERS_MANAGE, assigned: :manually)

      is_group = @assignment.respond_to?(:user_group)

      Form.transaction do
        if !is_group && @model.visible?
          @assignment.update!(
            user_role: @model.default_public_user_role,
            assigned: :automatically
          )
        else
          @assignment.destroy!
        end

        if is_group
          log_activity(:form_access_revoked_user_group, user_group: @assignment.user_group.id, role: @assignment.user_role.name)
        else
          log_activity(:form_access_revoked, user_target: @assignment.user.id, role: @assignment.user_role.name)
        end
      end

      render json: { message: t('access_permissions.destroy.success', member_name: is_group ? @assignment.user_group.name : @assignment.user.full_name) }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
      render json: { message: t('access_permissions.destroy.failure') }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end

    private

    def set_model
      @model = current_team.forms.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @model
    end

    def check_manage_permissions
      render_403 unless can_manage_form_users?(@model)
    end

    def check_read_permissions
      render_403 unless can_read_form?(@model) || can_manage_team?(@model.team)
    end
  end
end
