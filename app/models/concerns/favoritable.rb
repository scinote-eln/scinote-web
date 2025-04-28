# frozen_string_literal: true

module Favoritable
  extend ActiveSupport::Concern

  included do
    has_many :favorites, as: :item, inverse_of: :item, dependent: :destroy

    scope :favorite_for, ->(user) { joins(:favorites).where(favorites: { user: user }) }
    scope :with_favorites, lambda { |user|
      joins("LEFT JOIN favorites ON item_id = #{table_name}.id AND item_type = '#{name}' AND favorites.user_id = #{user.id}")
        .select("#{table_name}.*, favorites.id IS NOT NULL AS favorite")
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
