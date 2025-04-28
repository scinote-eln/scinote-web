# frozen_string_literal: true

module Favoritable
  extend ActiveSupport::Concern

  included do
    has_many :favorites, as: :item, inverse_of: :item, dependent: :destroy

    scope :favorite_for, ->(user) { joins(:favorites).where(favorites: { user: user }) }
  end

  def favorite!(user, favorite_team = nil)
    favorites.create!(user: user, team: favorite_team || team)
  end

  def unfavorite!(user, favorite_team = nil)
    favorites.find_by(user: user, team: favorite_team || team).destroy!
  end
end
