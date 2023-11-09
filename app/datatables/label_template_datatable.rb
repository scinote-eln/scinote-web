# frozen_string_literal: true

class LabelTemplateDatatable < CustomDatatableV2
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers

  TABLE_COLUMNS = {
    default: 'label_templates.default',
    name: 'label_templates.name',
    format: 'label_templates.type',
    description: 'label_templates.description',
    modified_by: 'label_templates.modified_by',
    updated_at: 'label_templates.updated_at',
    created_by: 'label_templates.created_by_user',
    created_at: 'label_templates.created_at'
  }.freeze

  def sortable_columns
    @sortable_columns ||= TABLE_COLUMNS
  end

  def searchable_columns
    @searchable_columns ||= TABLE_COLUMNS
  end

  private

  def order_params
    @order_params ||=
      params.require(:order).permit(:column, :dir).to_h
  end

  def data
    records.map do |record|
      {
        id: record.id,
        default: record.default,
        name: append_format_icon(record),
        format: escape_input(record.label_format),
        description: escape_input(record.description),
        modified_by: escape_input(record.modified_by),
        updated_at: I18n.l(record.updated_at, format: :full),
        created_by: escape_input(record.created_by_user),
        created_at: I18n.l(record.created_at, format: :full),
        attributes: {
          edit_url: label_template_path(record)
        }
      }
    end
  end

  def append_format_icon(record)
    {
      icon_image_tag:
        ActionController::Base.helpers.image_tag(
          "label_template_icons/#{record.icon}.svg",
          class: 'label-template-icon'
        ),
      name: escape_input(record.name)
    }
  end

  def get_raw_records
    res = @raw_data.joins(
      'LEFT OUTER JOIN users AS creators ' \
      'ON label_templates.created_by_id = creators.id'
    ).joins(
      'LEFT OUTER JOIN users AS modifiers '\
      'ON label_templates.last_modified_by_id = modifiers.id'
    ).select('label_templates.* AS label_templates')
                          .select('creators.full_name AS created_by_user')
                          .select('modifiers.full_name AS modified_by')
                          .select(
                            "('#{Extends::LABEL_TEMPLATE_FORMAT_MAP.to_json}'::jsonb -> label_templates.type)::text "\
                            "AS label_format"
                          )
    LabelTemplate.from(res, :label_templates)
  end

  def filter_records(records)
    records.where_attributes_like(
      ['label_templates.name', 'label_templates.label_format', 'label_templates.description',
       'label_templates.modified_by', 'label_templates.created_by_user'],
      params[:search]
    )
  end
end
