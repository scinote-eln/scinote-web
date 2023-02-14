# frozen_string_literal: true

module AccessPermissions
  class ProtocolsController < ApplicationController
    before_action :set_protocol
    before_action :check_read_permissions, only: %i(show)
    before_action :check_manage_permissions, except: %i(show)

    def new
      @user_assignment = UserAssignment.new(
        assignable: @protocol,
        assigned_by: current_user,
        team: current_team
      )

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
      @user_assignment = @protocol.user_assignments.find_by(
        user_id: permitted_update_params[:user_id],
        team: current_team
      )
      @user_assignment.update(permitted_update_params)
      respond_to do |format|
        format.json do
          render :protocol_member
        end
      end
    end

    def create
      ActiveRecord::Base.transaction do
        permitted_create_params[:resource_members].each do |_k, user_assignment_params|
          next unless user_assignment_params[:assign] == '1'

          user_assignment = UserAssignment.new(user_assignment_params)
          user_assignment.assignable = @protocol
          user_assignment.team = current_team
          user_assignment.assigned_by = current_user
          user_assignment.save!
        end

        respond_to do |format|
          @message = t('access_permissions.create.success', count: @protocol.user_assignments.count)
          format.json { render :edit }
        end
      rescue ActiveRecord::RecordInvalid
        respond_to do |format|
          @message = t('access_permissions.create.failure')
          format.json { render :new }
        end
      end
    end

    def destroy
      user = @protocol.assigned_users.find(params[:user_id])
      user_assignment = @protocol.user_assignments.find_by(user: user, team: current_team)
      respond_to do |format|
        if user_assignment.destroy
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

    private

    def permitted_update_params
      params.require(:user_assignment)
            .permit(%i(user_role_id user_id))
    end

    def permitted_create_params
      params.require(:access_permissions_new_user_form)
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
      render_403 unless can_read_protocol_in_repository?(@protocol)
    end
  end
end
