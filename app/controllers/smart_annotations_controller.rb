class SmartAnnotationsController < ApplicationController
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  def parse_string
    render json: {
      annotations: custom_auto_link(
        params[:string],
        simple_format: false,
        tags: %w(img),
        team: current_team
      )
    }
  end
end
