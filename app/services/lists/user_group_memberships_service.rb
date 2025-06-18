# frozen_string_literal: true

module Lists
  class UserGroupMembershipsService < BaseService
    private

    def fetch_records
      @records = @raw_data.joins(:user).includes(:user)
    end

    def filter_records
      return unless @params[:search]

      @records = @records.where_attributes_like(
        ['users.full_name', 'users.email'],
        @params[:search]
      )
    end

    def sortable_columns
      @sortable_columns ||= {
        name: 'users.full_name',
        email: 'users.email',
        created_at: 'user_group_memberships.created_at'
      }
    end
  end
end
