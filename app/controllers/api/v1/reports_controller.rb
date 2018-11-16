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
        render jsonapi: reports,
               each_serializer: ReportSerializer,
               hide_project: true
      end

      def show
        render jsonapi: @report,
               serializer: ReportSerializer,
               hide_project: true,
               include: :user
      end

      private

      def load_report
        @report = @project.reports.find(params.require(:id))
      end
    end
  end
end
