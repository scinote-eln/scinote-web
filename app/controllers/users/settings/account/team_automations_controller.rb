# frozen_string_literal: true

module Users
  module Settings
    module Account
      class TeamAutomationsController < ApplicationController
        before_action :load_team
        before_action :check_manage_permissions, only: %i(index update team)
        before_action :set_breadcrumbs_items, only: %i(index)
        layout 'fluid'

        def index; end

        def update
          @team.settings.merge!(update_params)
          if @team.save
            render json: { status: :ok }
          else
            render json: @team.errors, status: :unprocessable_entity
          end
        end

        def team
          render json: {
            teamName: @team.name,
            teamAutomationGroups: Extends::TEAM_AUTOMATION_GROUPS,
            teamSettings: @team.settings,
            updateUrl: users_settings_account_team_automation_path(@team)
          }
        end

        private

        def load_team
          @team = current_team
        end

        def update_params
          params.require(:team).permit(team_automation_settings: {})
        end

        def check_manage_permissions
          render_403 unless can_manage_team?(@team)
        end

        def set_breadcrumbs_items
          @breadcrumbs_items = [{
            label: t('breadcrumbs.team_automations'),
            url: users_settings_account_team_automations_path
          }]

          @breadcrumbs_items
        end
      end
    end
  end
end
