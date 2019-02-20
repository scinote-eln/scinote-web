# frozen_string_literal: true

module SearchableByNameModel
  extend ActiveSupport::Concern

  included do
    def self.search_by_name(user, teams = [], query = nil, options = {})
      return if user.blank? || teams.blank?
      viewable_by_user(user, teams)
        .where_attributes_like("#{table_name}.name", query, options)
        .limit(Constants::SEARCH_LIMIT)
    end
  end
end
