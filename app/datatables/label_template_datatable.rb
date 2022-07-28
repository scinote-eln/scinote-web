# frozen_string_literal: true

class LabelTemplateDatatable < CustomDatatable
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers

  TABLE_COLUMNS = %w(
    label_templates.name
    label_templates.format
    label_templates.description
    label_templates.modified_by
    label_templates.updated_at
    label_templates.created_by_user
    label_templates.created_at
  ).freeze

  def initialize(view, can_manage_templates, label_templates)
    super(view)
    @manage_template = can_manage_templates
    @label_templates = label_templates
  end

  def sortable_columns
    @sortable_columns ||= TABLE_COLUMNS
  end

  def searchable_columns
    @searchable_columns ||= TABLE_COLUMNS
  end

  private

  def data
    records.map do |record|
      {
        '0' => record.id,
        '1' => record.default,
        '2' => append_format_icon(sanitize_input(record.name)),
        '3' => sanitize_input(record.format),
        '4' => sanitize_input(record.description),
        '5' => sanitize_input(record.modified_by),
        '6' => I18n.l(record.updated_at, format: :full),
        '7' => sanitize_input(record.created_by_user),
        '8' => I18n.l(record.created_at, format: :full),
        'recordInfoUrl' => '',
        'DT_RowAttr': {
          'data-edit-url': edit_label_template_path(record),
          'data-set-default-url': set_default_label_template_path(record)
        },
        'manage_permission' => @manage_template
      }
    end
  end

  def append_format_icon(data)
    { icon_url: ActionController::Base.helpers.image_tag('label_template_icons/zpl.svg', class: 'label-template-icon'),
      name: data }
  end

  def get_raw_records
    res = @label_templates.joins(
      'LEFT OUTER JOIN users AS creators ' \
      'ON label_templates.created_by_id = creators.id'
    ).joins(
      'LEFT OUTER JOIN users AS modifiers '\
      'ON label_templates.last_modified_by_id = modifiers.id'
    ).select('label_templates.* AS label_templates')
                          .select('creators.full_name AS created_by_user')
                          .select('modifiers.full_name AS modified_by')
    LabelTemplate.from(res, :label_templates)
  end

  def filter_records(records)
    records.where_attributes_like(
      ['label_templates.name', 'label_templates.format', 'label_templates.description',
       'label_templates.modified_by', 'label_templates.created_by_user'],
      dt_params.dig(:search, :value)
    )
  end
end
