# frozen_string_literal: true

class LabelTemplatesController < ApplicationController
  before_action :check_view_permissions

  layout 'fluid'

  def index; end

  private

  def check_view_permissions
    render_403 unless can_view_label_templates?(current_team)
  end
end
