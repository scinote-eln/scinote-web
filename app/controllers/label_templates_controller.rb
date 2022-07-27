# frozen_string_literal: true

class LabelTemplatesController < ApplicationController
  include InputSanitizeHelper

  before_action :check_view_permissions
  before_action :load_label_templates, only: %i(index datatable)

  layout 'fluid'

  def index; end

  def datatable
    respond_to do |format|
      format.json do
        render json: ::LabelTemplateDatatable.new(
          view_context,
          can_manage_label_templates?(current_team),
          @label_templates
        )
      end
    end
  end

  def new
    render_404
  end

  private

  def check_view_permissions
    render_403 unless can_view_label_templates?(current_team)
  end

  def load_label_templates
    @label_templates = LabelTemplate.where(team_id: current_team.id)
  end
end
