# frozen_string_literal: true

class LabelTemplateDatatable < CustomDatatable
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers

  TABLE_COLUMNS = %w(
    label_templates.name
    label_templates.created_at
    label_templates.updated_at
    label_templates.default
  ).freeze

  def initialize(view, label_templates)
    super(view)
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
        '3' => I18n.l(record.created_at, format: :full),
        '4' => I18n.l(record.updated_at, format: :full)
      }
    end
  end

  def append_format_icon(data)
    { icon_url: ActionController::Base.helpers.image_tag('label_template_icons/zpl.svg', class: 'label-template-icon'),
      name: data }
  end

  def get_raw_records
    @label_templates
  end

  def filter_records(records)
    records.where_attributes_like(
      ['label_templates.name'],
      dt_params.dig(:search, :value)
    )
  end
end
