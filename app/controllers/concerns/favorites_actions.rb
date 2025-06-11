# frozen_string_literal: true

module FavoritesActions
  extend ActiveSupport::Concern

  included do
    before_action :load_favorite_item, only: %i(favorite unfavorite)
  end

  def favorite
    @favorite_item.favorite!(current_user, current_team)
    head :ok
  end

  def unfavorite
    @favorite_item.unfavorite!(current_user, current_team)
    head :ok
  end

  private

  def load_favorite_item
    @favorite_item = controller_name.singularize.camelize.constantize.find(params[:id])

    render_403 unless public_send(:"can_read_#{controller_name.singularize}?", @favorite_item)
  end
end
