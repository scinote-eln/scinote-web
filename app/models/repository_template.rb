# frozen_string_literal: true

class RepositoryTemplate < ApplicationRecord
  belongs_to :team, inverse_of: :repository_templates
  has_many :repositories, inverse_of: :repository_template, dependent: :nullify

  def self.default
    RepositoryTemplate.new(
      name: I18n.t('repository_templates.default_template_name'),
      column_definitions: [],
      predefined: true
    )
  end

  def self.cell_lines
    RepositoryTemplate.new(
      name: I18n.t('repository_templates.cell_lines_template_name'),
      column_definitions: [
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.species') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.organ') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryListValue],
          params: { name: I18n.t('repository_templates.template_columns.morphology'),
                    metadata: { delimiter: I18n.t('repository_templates.repository_list_value_delimiter') },
                    repository_list_items_attributes: [{ data: I18n.t('repository_templates.template_columns.repository_list_value.endothelial') },
                                                       { data: I18n.t('repository_templates.template_columns.repository_list_value.epithelial') },
                                                       { data: I18n.t('repository_templates.template_columns.repository_list_value.fibroblast') },
                                                       { data: I18n.t('repository_templates.template_columns.repository_list_value.lymphoblast') }] }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryListValue],
          params: { name: I18n.t('repository_templates.template_columns.culture_type'),
                    metadata: { delimiter: I18n.t('repository_templates.repository_list_value_delimiter') },
                    repository_list_items_attributes: [{ data: I18n.t('repository_templates.template_columns.repository_list_value.adherent') },
                                                       { data: I18n.t('repository_templates.template_columns.repository_list_value.suspension') }] }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryStockValue],
          params: { name: I18n.t('repository_templates.template_columns.stock'),
                    metadata: { decimals: 2 },
                    repository_stock_unit_items_attributes: RepositoryStockUnitItem::DEFAULT_UNITS.map { |unit| { data: unit } } +
                                                            [{ data: I18n.t('repository_templates.template_columns.stock_units.vials') }] }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryNumberValue],
          params: { name: I18n.t('repository_templates.template_columns.passage_number') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.lot_number') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryDateValue],
          params: { name: I18n.t('repository_templates.template_columns.freezing_date') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.operator') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.yield') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryStatusValue],
          params: { name: I18n.t('repository_templates.template_columns.status'),
                    repository_status_items_attributes: [{ status: I18n.t('repository_templates.template_columns.repository_status_value.frozen'), icon: '❄️' },
                                                         { status: I18n.t('repository_templates.template_columns.repository_status_value.in_subculturing'), icon: '🧫' },
                                                         { status: I18n.t('repository_templates.template_columns.repository_status_value.out_of_tock'), icon: '❌' }] }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryAssetValue],
          params: { name: I18n.t('repository_templates.template_columns.handling_procedure') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.notes') }
        }
      ],
      predefined: true
    )
  end

  def self.equipment
    RepositoryTemplate.new(
      name: I18n.t('repository_templates.equipment_template_name'),
      column_definitions: [
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryDateValue],
          params: { name: I18n.t('repository_templates.template_columns.calibration_date'),
                    reminder_value: '1', reminder_unit: '2419200', reminder_message: I18n.t('repository_templates.template_columns.calibration_message') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryStatusValue],
          params: { name: I18n.t('repository_templates.template_columns.availability_status'),
                    repository_status_items_attributes: [{ status: I18n.t('repository_templates.template_columns.repository_status_value.available_for_use'), icon: '🟢' },
                                                         { status: I18n.t('repository_templates.template_columns.repository_status_value.in_use'), icon: '🟥' },
                                                         { status: I18n.t('repository_templates.template_columns.repository_status_value.out_of_service'), icon: '❌' },
                                                         { status: I18n.t('repository_templates.template_columns.repository_status_value.under_maintenance'), icon: '🔧' }] }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryAssetValue],
          params: { name: I18n.t('repository_templates.template_columns.safety_handling_info') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryAssetValue],
          params: { name: I18n.t('repository_templates.template_columns.training_records') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.contact_person') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.contact_phone') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.internal_id') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.manufacturer') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.serial_number') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.notes') }
        }
      ],
      predefined: true
    )
  end

  def self.chemicals_and_reagents
    RepositoryTemplate.new(
      name: I18n.t('repository_templates.chemicals_and_reagents_template_name'),
      column_definitions: [
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.concentration') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryStockValue],
          params: { name: I18n.t('repository_templates.template_columns.stock'),
                    metadata: { decimals: 2 },
                    repository_stock_unit_items_attributes: RepositoryStockUnitItem::DEFAULT_UNITS.map { |unit| { data: unit } } }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryDateValue],
          params: { name: I18n.t('repository_templates.template_columns.date_opened') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryDateValue],
          params: { name: I18n.t('repository_templates.template_columns.expiration_date'),
                    reminder_value: '1', reminder_unit: '2419200', reminder_message: I18n.t('repository_templates.template_columns.expiration_date_message') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryListValue],
          params: { name: I18n.t('repository_templates.template_columns.storage_conditions'),
                    metadata: { delimiter: I18n.t('repository_templates.repository_list_value_delimiter') },
                    repository_list_items_attributes: [{ data: I18n.t('repository_templates.template_columns.repository_list_value.minus_twenty_celsious') },
                                                       { data: I18n.t('repository_templates.template_columns.repository_list_value.two_to_eigth_celsious') },
                                                       { data: I18n.t('repository_templates.template_columns.repository_list_value.minus_eigthty') },
                                                       { data: I18n.t('repository_templates.template_columns.repository_list_value.ambient') }] }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryListValue],
          params: { name: I18n.t('repository_templates.template_columns.type'),
                    metadata: { delimiter: I18n.t('repository_templates.repository_list_value_delimiter') },
                    repository_list_items_attributes: [{ data: I18n.t('repository_templates.template_columns.repository_list_value.buffer') },
                                                       { data: I18n.t('repository_templates.template_columns.repository_list_value.liquid') },
                                                       { data: I18n.t('repository_templates.template_columns.repository_list_value.reagent') },
                                                       { data: I18n.t('repository_templates.template_columns.repository_list_value.solid') }] }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.purity') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.cas_number') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryAssetValue],
          params: { name: I18n.t('repository_templates.template_columns.safety_sheet') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryListValue],
          params: { name: I18n.t('repository_templates.template_columns.vendor') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.catalog_number') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.lot') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.price') }
        },
        {
          column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
          params: { name: I18n.t('repository_templates.template_columns.molecular_weight') }
        }
      ],
      predefined: true
    )
  end
end
