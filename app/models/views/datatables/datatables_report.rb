# frozen_string_literal: true

module Views
  module Datatables
    class DatatablesReport < ApplicationRecord
      belongs_to :team

      # this isn't strictly necessary, but it will prevent
      # rails from calling save, which would fail anyway.
      def readonly?
        true
      end

      class << self
        def visible_by(user, team)
          permitted_by_team    = get_permitted_by_team_tokenized
          permitted_by_project = get_permitted_by_project_tokenized
          if user.is_admin_of_team? team
            allowed_ids = for_admin(user, permitted_by_team)
          else
            allowed_ids = for_non_admin(
              user, permitted_by_team, permitted_by_project
            )
          end
          where(id: allowed_ids).where(project_archived: false)
        end

        def refresh_materialized_view
          Scenic.database.refresh_materialized_view(:datatables_reports,
                                                    concurrently: true,
                                                    cascade: false)
        end

        private

        PermissionItem = Struct.new(:report_id, :users_ids, :visibility)

        def tokenize(items)
          items.collect do |item|
            PermissionItem.new(item[0], item[1], item[2])
          end
        end

        def get_permitted_by_team_tokenized
          tokenize(pluck(:id, :users_with_team_read_permissions, :project_visibility))
        end

        def get_permitted_by_project_tokenized
          tokenize(pluck(:id, :users_with_project_read_permissions, :project_visibility))
        end

        def get_by_project_item(permitted_by_project, item)
          permitted_by_project.select { |el| el.report_id == item.report_id }
                              .first
        end

        def for_admin(user, permitted_by_team)
          allowed_ids = []
          permitted_by_team.each do |item|
            next unless user.id.in? item.users_ids
            allowed_ids << item.report_id
          end
          allowed_ids
        end

        def for_non_admin(user, permitted_by_team, permitted_by_project)
          allowed_ids = []
          permitted_by_team.each do |item|
            next unless user.id.in? item.users_ids
            by_project = get_by_project_item(permitted_by_project, item)
            next unless user_can_view?(user, by_project)
            allowed_ids << item.report_id
          end
          allowed_ids
        end

        def user_can_view?(user, by_project)
          user.id.in?(by_project.users_ids) || by_project.visibility == 1
        end
      end
    end
  end
end
