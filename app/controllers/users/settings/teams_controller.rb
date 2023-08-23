# frozen_string_literal: true

module Users
  module Settings
    class TeamsController < ApplicationController
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::UrlHelper
      include ApplicationHelper
      include InputSanitizeHelper

      before_action :load_user, only: %i(
        index
        datatable
        new
        create
        show
        users_datatable
      )

      before_action :load_team, only: %i(
        show
        users_datatable
        name_html
        description_html
        update
        destroy
      )

      before_action :check_create_team_permission,
                    only: %i(new create)

      before_action :set_breadcrumbs_items, only: %i(index show)

      layout 'fluid'

      def index
        @member_of = @user.teams.count
      end

      def datatable
        render json: ::TeamsDatatable.new(view_context, @user)
      end

      def new
        @new_team = Team.new
      end

      def create
        @new_team = Team.new(create_params)
        @new_team.created_by = @user

        if @new_team.save
          # Redirect to new team page
          redirect_to team_path(@new_team)
        else
          render :new
        end
      end

      def show; end

      def users_datatable
        render json: ::TeamUsersDatatable.new(view_context, @team, @user)
      end

      def name_html
        render json: {
          html: render_to_string(
            partial: 'users/settings/teams/name_modal_body',
            locals: { team: @team },
            formats: :html
          )
        }
      end

      def description_html
        render json: {
          html: render_to_string(
            partial: 'users/settings/teams/description_modal_body',
            locals: { team: @team },
            formats: :html
          )
        }
      end

      def update
        if @team.update(update_params)
          @team.update(last_modified_by: current_user)
          render json: {
            status: :ok,
            html: custom_auto_link(
              @team.tinymce_render(:description),
              simple_format: false,
              tags: %w(img),
              team: current_team
            )
          }
        else
          render json: @team.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @team.destroy

        flash[:notice] = I18n.t(
          'users.settings.teams.edit.modal_destroy_team.flash_success',
          team: @team.name
        )

        # Redirect back to all teams page
        redirect_to action: :index
      end

      def switch
        team = current_user.teams.find_by(id: params[:team_id])

        if team && current_user.update(current_team_id: team.id)
          flash[:success] = t('users.settings.changed_team_flash',
                              team: current_user.current_team.name)
          render json: { current_team: team.id }
        else
          render json: { message: t('users.settings.changed_team_error_flash') }, status: :unprocessable_entity
        end
      end

      private

      def check_create_team_permission
        render_403 unless can_create_teams?
      end

      def load_user
        @user = current_user
      end

      def load_team
        @team = Team.find_by(id: params[:id])
        render_403 unless can_manage_team?(@team)
      end

      def create_params
        params.require(:team).permit(
          :name,
          :description
        )
      end

      def update_params
        params.require(:team).permit(
          :name,
          :description
        )
      end

      def set_breadcrumbs_items
        @breadcrumbs_items = []

        @breadcrumbs_items.push({
                                  label: t('breadcrumbs.teams'),
                                  url: teams_path
                                })
        if @team
          @breadcrumbs_items.push({
                                    label: @team.name,
                                    url: team_path(@team)
                                  })
        end
      end
    end
  end
end
