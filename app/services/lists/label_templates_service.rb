# frozen_string_literal: true

module Lists
  class LabelTemplatesService < BaseService
    private

    def fetch_records
      res = @raw_data.joins(
        'LEFT OUTER JOIN users AS creators ' \
        'ON label_templates.created_by_id = creators.id'
      ).joins(
        'LEFT OUTER JOIN users AS modifiers ' \
        'ON label_templates.last_modified_by_id = modifiers.id'
      ).select('label_templates.* AS label_templates')
                     .select('creators.full_name AS created_by_user')
                     .select('modifiers.full_name AS modified_by')
                     .select(
                       "('#{Extends::LABEL_TEMPLATE_FORMAT_MAP.to_json}'::jsonb -> label_templates.type)::text " \
                       "AS label_format"
                     )
      @records = LabelTemplate.from(res, :label_templates)
    end

    def filter_records
      return unless @params[:search]

      @records = @records.where_attributes_like(
        ['label_templates.name', 'label_templates.label_format', 'label_templates.description',
         'label_templates.modified_by', 'label_templates.created_by_user'],
        @params[:search]
      )
    end

    def sort_records
      return unless @params[:order]

      sorted_column = sortable_columns[order_params[:column].to_sym]

      # Handle null values in description column
      if sorted_column == 'label_templates.description'
        sort_by = "COALESCE(label_templates.description, '') ASC"
        sort_by = "COALESCE(label_templates.description, '') DESC" if sort_direction(order_params) == 'DESC'
        @records = @records.order(Arel.sql(sort_by)).order(:id)
      else
        super
      end
    end

    def sortable_columns
      @sortable_columns ||= {
        default: 'label_templates.default',
        name: 'label_templates.name',
        format: 'label_templates.type',
        description: 'label_templates.description',
        modified_by: 'label_templates.modified_by',
        updated_at: 'label_templates.updated_at',
        created_by: 'label_templates.created_by_user',
        created_at: 'label_templates.created_at'
      }
    end
  end
end
