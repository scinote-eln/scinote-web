# frozen_string_literal: true

class TagsController < ApplicationController
  def index
    @tags = if params[:teams].present?
              Tag.where(team: current_user.teams.where(id: params[:teams])).order(:name)
            else
              current_team.tags.order(:name)
            end
    @tags = @tags.where_attributes_like(['tags.name'], params[:query]) if params[:query].present?
  end

  def colors
    render json: { colors: Constants::TAG_COLORS }
  end
end
