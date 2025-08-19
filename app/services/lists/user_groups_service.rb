# frozen_string_literal: true

module Lists
  class UserGroupsService < BaseService
    private

    def fetch_records
      @records = @raw_data.left_joins(:created_by).left_joins(:user_group_memberships).includes(:users)
                          .select('user_groups.*')
                          .select('array_agg(users.full_name) AS created_by_user')
                          .select('COUNT(user_groups.id) AS members_count')
                          .group('user_groups.id')
    end

    def filter_records
      return unless @params[:search]

      @records = @records.where_attributes_like(
        ['user_groups.name'],
        @params[:search]
      )
    end

    def sort_records
      return unless @params[:order]

      sorted_column = sortable_columns[order_params[:column].to_sym]

      if sorted_column == 'user_groups.members'
        sort_by = "members_count #{sort_direction(order_params)}"
        @records = @records.order(Arel.sql(sort_by))
      else
        super
      end
    end

    def sortable_columns
      @sortable_columns ||= {
        name: 'user_groups.name',
        members: 'user_groups.members',
        updated_at: 'user_groups.updated_at',
        created_by: 'created_by_user',
        created_at: 'user_groups.created_at'
      }
    end
  end
end
