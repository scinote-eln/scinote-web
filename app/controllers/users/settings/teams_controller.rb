module Users
  module Settings
    class TeamsController < ApplicationController
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::UrlHelper
      include ApplicationHelper
      include InputSanitizeHelper

      before_action :load_user, only: [
        :index,
        :datatable,
        :new,
        :create,
        :show,
        :users_datatable
      ]

      before_action :load_team, only: [
        :show,
        :users_datatable,
        :name_html,
        :description_html,
        :update,
        :destroy
      ]

      before_action :check_create_team_permission,
                    only: %i(new create)

      layout 'fluid'

      def index
        @user_teams =
          @user
          .user_teams
          .includes(team: :users)
          .order(created_at: :asc)
        @member_of = @user_teams.count
      end

      def datatable
        respond_to do |format|
          format.json do
            render json: ::TeamsDatatable.new(view_context, @user)
          end
        end
      end

      def new
        @new_team = Team.new
      end

      def create
        @new_team = Team.new(create_params)
        @new_team.created_by = @user

        if @new_team.save
          # Okay, team is created, now
          # add the current user as admin
          UserTeam.create(
            user: @user,
            team: @new_team,
            role: 2
          )

          # Redirect to new team page
          redirect_to team_path(@new_team)
        else
          render :new
        end
      end

      def show
        @user_team = UserTeam.find_by(user: @user, team: @team)
      end

      def users_datatable
        respond_to do |format|
          format.json do
            render json: ::TeamUsersDatatable.new(view_context, @team, @user)
          end
        end
      end

      def name_html
        respond_to do |format|
          format.json do
            render json: {
              html: render_to_string(
                partial: 'users/settings/teams/name_modal_body.html.erb',
                locals: { team: @team }
              )
            }
          end
        end
      end

      def description_html
        respond_to do |format|
          format.json do
            render json: {
              html: render_to_string(
                partial: 'users/settings/teams/description_modal_body.html.erb',
                locals: { team: @team }
              )
            }
          end
        end
      end

      def update
        respond_to do |format|
          if @team.update(update_params)
            @team.update(last_modified_by: current_user)
            format.json do
              render json: {
                status: :ok,
                html: custom_auto_link(
                  @team.tinymce_render(:description),
                  simple_format: false,
                  tags: %w(img),
                  team: current_team
                )
              }
            end
          else
            format.json do
              render json: @team.errors,
              status: :unprocessable_entity
            end
          end
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

      private

      def check_create_team_permission
        render_403 unless can_create_teams?
      end

      def load_user
        @user = current_user
      end

      def load_team
        @team = Team.find_by_id(params[:id])
        render_403 unless can_update_team?(@team)
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
    end
  end
end
