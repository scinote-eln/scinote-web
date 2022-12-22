# frozen_string_literal: true

module AccessPermissions
  class ProtocolsController < ApplicationController
    before_action :set_protocol
    before_action :check_read_permissions, only: %i(show)
    before_action :check_manage_permissions, except: %i(show)

    def new
      respond_to do |format|
        format.json
      end
    end

    def show
      respond_to do |format|
        format.json
      end
    end

    def edit
      respond_to do |format|
        format.json
      end
    end

    def update
      @user_assignment = UserAssignment.find_by(user_id: permitted_update_params[:user_id], assignable: @protocol)
      @user_assignment.update(permitted_update_params)
      respond_to do |format|
        format.json do
          render :protocol_member
        end
      end
    end

    def create
      respond_to do |format|
        if @form.save
          @message = t('access_permissions.create.success', count: @form.new_members_count)
          format.json { render :edit }
        else
          @message = t('access_permissions.create.failure')
          format.json { render :new }
        end
      end
    end

    def destroy
      respond_to do |format|
        if project_member.destroy
          format.json do
            render json: { flash: t('access_permissions.destroy.success', member_name: user.full_name) },
                   status: :ok
          end
        else
          format.json do
            render json: { flash: t('access_permissions.destroy.failure') },
                   status: :unprocessable_entity
          end
        end
      end
    end

    def update_default_public_user_role
      @protocol.update!(permitted_default_public_user_role_params)
    end

    private

    def permitted_default_public_user_role_params
      params.require(:protocol).permit(:default_public_user_role_id)
    end

    def permitted_update_params
      params.require(:user_assignment)
            .permit(%i(user_role_id user_id))
    end

    def permitted_create_params
      params.require(:access_permissions_new_user_protocol_form)
            .permit(resource_members: %i(assign user_id user_role_id))
    end

    def set_protocol
      @protocol = current_team.protocols.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @protocol
    end

    def check_manage_permissions
      render_403 unless can_manage_protocol_users?(@protocol)
    end

    def check_read_permissions
      render_403 unless can_read_protocol?(@protocol)
    end
  end
end
