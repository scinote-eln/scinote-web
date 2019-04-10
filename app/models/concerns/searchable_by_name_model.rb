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

    def self.filter_by_teams(teams = [])
      return self if teams.empty?
      if column_names.include? 'team_id'
        return where(team_id: teams)
      else
        valid_subjects = Extends::ACTIVITY_SUBJECT_CHILDREN
        parent_array = [to_s.underscore]
        find_parent = true
        # Trying to build parent array
        while find_parent
          possible_parent = valid_subjects.find { |_sub, ch| ((ch || []).include? parent_array[-1].pluralize.to_sym) }
          possible_parent = { Project: nil } if parent_array[-1] == 'experiment'
          if possible_parent
            parent_array.push(possible_parent.flatten[0].to_s.underscore)
          else
            find_parent = false
          end
        end
        parent_array.shift
        # Now we will go from parent to child direction
        last_parent = parent_array.reverse!.shift
        query = last_parent.to_s.camelize.constantize.where(team_id: teams)
        parent_array.each do |child|
          query = child.to_s.camelize.constantize.where("#{last_parent}_id" => query)
          last_parent = child
        end
        return where("#{last_parent}_id" => query)
      end
    end
  end
end
