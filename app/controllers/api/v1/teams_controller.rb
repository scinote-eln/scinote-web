module Api
  module V1
    class TeamsController < BaseController
      before_action :load_team, only: :show

      def index
        teams = current_user.teams.page(params[:page]).per(params[:page_size])
        render json: teams, each_serializer: TeamSerializer
      end

      def show
        render json: @team, serializer: TeamSerializer
      end

      private

      def load_team
        @team = Team.find(params.require(:id))
        return render json: {}, status: :not_found unless @team
        return render json: {}, status: :forbidden unless can_read_team?(@team)
      end
    end
  end
end
