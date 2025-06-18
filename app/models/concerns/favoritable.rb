# frozen_string_literal: true

module Favoritable
  extend ActiveSupport::Concern

  included do
    has_many :favorites, as: :item, inverse_of: :item, dependent: :destroy

    scope :favorite_for, ->(user) { joins(:favorites).where(favorites: { user: user }) }
    scope :with_favorites, lambda { |user|
      favorite_exists_subquery =
        Favorite
        .where("favorites.item_id = #{table_name}.id")
        .where(item_type: name, user_id: user.id)
        .select('1')

      select("#{table_name}.*, EXISTS (#{favorite_exists_subquery.to_sql}) AS favorite")
    }
  end

  def favorite!(user, favorite_team = nil)
    favorites.create!(user: user, team: favorite_team || team)
  end

  def unfavorite!(user, favorite_team = nil)
    favorites.find_by(user: user, team: favorite_team || team).destroy!
  end

  def favorite
    attributes['favorite']
  end
end
