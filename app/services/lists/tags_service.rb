# frozen_string_literal: true

module Lists
  class TagsService < BaseService
    private

    def fetch_records
      @records = @raw_data.left_joins(:created_by, :taggings)
                          .select('tags.*')
                          .select('array_agg(users.full_name) AS created_by_user')
                          .select('COUNT(taggings.id) AS taggings_count')
                          .group('tags.id')
    end

    def filter_records
      return unless @params[:search]

      @records = @records.where_attributes_like(
        ['tags.name'],
        @params[:search]
      )
    end

    def sort_records
      return unless @params[:order]

      sorted_column = sortable_columns[order_params[:column].to_sym]

      if sorted_column == 'tags.taggings_count'
        sort_by = "taggings_count #{sort_direction(order_params)}"
        @records = @records.order(Arel.sql(sort_by))
      else
        super
      end
    end

    def sortable_columns
      @sortable_columns ||= {
        name: 'tags.name',
        color: 'tags.color',
        taggings_count: 'tags.taggings_count',
        updated_at: 'tags.updated_at',
        created_by: 'created_by_user',
        created_at: 'tags.created_at'
      }
    end
  end
end
