# frozen_string_literal: true

class TagsController < ApplicationController
  def index
    @tags = current_team.tags.order(:name)
  end
end
