# frozen_string_literal: true

module Api
  module V1
    class ReportsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_report, only: :show

      def index
        reports = @project.reports
                          .page(params.dig(:page, :number))
                          .per(params.dig(:page, :size))

        render jsonapi: reports, each_serializer: ReportSerializer
      end

      def show
        render jsonapi: @report, serializer: ReportSerializer
      end

      private

      def load_team
        @team = Team.find(params.require(:team_id))
        render jsonapi: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_project
        @project = @team.projects.find(params.require(:project_id))
        render jsonapi: {}, status: :forbidden unless can_read_project?(
          @project
        )
      end

      def load_report
        @report = @project.reports.find(params.require(:id))
        render jsonapi: {}, status: :not_found if @report.nil?
      end
    end
  end
end
