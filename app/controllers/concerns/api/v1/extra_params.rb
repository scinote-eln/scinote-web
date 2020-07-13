# frozen_string_literal: true

module Api
  module V1
    module ExtraParams
      extend ActiveSupport::Concern

      def render_rte?
        params[:render_rte] == 'true'
      end
    end
  end
end
