# frozen_string_literal: true

class RepositoryStockValue < ApplicationRecord
  include RepositoryValueWithReminders
  include ActionView::Helpers::NumberHelper

  attribute :comment, :text

  belongs_to :repository_stock_unit_item, optional: true
  belongs_to :created_by, class_name: 'User', optional: true, inverse_of: :created_repository_stock_values
  belongs_to :last_modified_by, class_name: 'User', optional: true, inverse_of: :modified_repository_stock_values
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  has_one :repository_row, through: :repository_cell
  has_many :repository_ledger_records, dependent: :destroy
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true
  validates :low_stock_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :update_consumption_stock_units, if: :repository_stock_unit_item_id_changed?
  after_save :send_low_stock_notification, if: -> { status == :low }

  after_create do
    next if is_a?(RepositoryStockConsumptionValue)

    repository_ledger_records.create!(user: created_by,
                                      amount: amount,
                                      balance: amount,
                                      reference: repository_cell.repository_column.repository,
                                      comment: comment,
                                      unit: repository_stock_unit_item&.data)
  end

  SORTABLE_COLUMN_NAME = 'repository_stock_values.amount'

  def formatted
    "#{formatted_value} #{repository_stock_unit_item&.data}"
  end

  def formatted_value
    if repository_cell
      number_with_precision(
        amount,
        precision: (repository_cell.repository_column.metadata['decimals'].to_i || 0),
        strip_insignificant_zeros: true
      )
    end
  end

  def formatted_treshold
    if repository_cell && low_stock_threshold
      number_with_precision(
        low_stock_threshold,
        precision: (repository_cell.repository_column.metadata['decimals'].to_i || 0),
        strip_insignificant_zeros: true
      )
    end
  end

  def status
    return :empty if amount <= 0

    return :low if low_stock_threshold && amount <= low_stock_threshold

    :normal
  end

  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    parameters = filter_element.parameters
    if filter_element.operator == 'between'
      return repository_rows if parameters['from'].blank? || parameters['to'].blank?
    elsif parameters['value'].blank?
      return repository_rows
    end

    repository_rows = case parameters['stock_unit']
                      when 'all'
                        repository_rows.where("#{join_alias}.repository_stock_unit_item_id IS NOT NULL")
                      when 'none'
                        repository_rows.where("#{join_alias}.repository_stock_unit_item_id IS NULL")
                      else
                        repository_rows.where("#{join_alias}.repository_stock_unit_item_id = ?", parameters['stock_unit'])
                      end

    case filter_element.operator
    when 'equal_to'
      repository_rows.where("#{join_alias}.amount = ?", parameters['value'].to_d)
    when 'unequal_to'
      repository_rows.where.not("#{join_alias}.amount = ?", parameters['value'].to_d)
    when 'greater_than'
      repository_rows.where("#{join_alias}.amount > ?", parameters['value'].to_d)
    when 'greater_than_or_equal_to'
      repository_rows.where("#{join_alias}.amount >= ?", parameters['value'].to_d)
    when 'less_than'
      repository_rows.where("#{join_alias}.amount < ?", parameters['value'].to_d)
    when 'less_than_or_equal_to'
      repository_rows.where("#{join_alias}.amount <= ?", parameters['value'].to_d)
    when 'between'
      repository_rows
        .where("#{join_alias}.amount > ? AND #{join_alias}.amount < ?", parameters['from'].to_d, parameters['to'].to_d)
    else
      raise ArgumentError, 'Wrong operator for RepositoryStockValue!'
    end
  end

  def data_different?(new_data)
    BigDecimal(new_data[:amount].to_s) != amount ||
      (new_data[:unit_item_id].present? && new_data[:unit_item_id] != repository_stock_unit_item.id)
  end

  def update_data!(new_data, user)
    self.low_stock_threshold = new_data[:low_stock_threshold].presence if new_data[:low_stock_threshold]
    self.repository_stock_unit_item = repository_cell
                                      .repository_column
                                      .repository_stock_unit_items
                                      .find_by(id: new_data[:unit_item_id])
    self.last_modified_by = user
    new_amount = new_data[:amount].to_d
    delta = new_amount - amount.to_d
    self.comment = new_data[:comment].presence
    repository_ledger_records.create!(
      user: last_modified_by,
      amount: delta,
      balance: new_amount,
      reference: repository_cell.repository_column.repository,
      comment: comment,
      unit: repository_stock_unit_item&.data
    )
    self.amount = new_amount
    save!
  end

  def snapshot!(cell_snapshot)
    value_snapshot = dup
    stock_unit_item =
      if repository_stock_unit_item.present?
        cell_snapshot.repository_column
                     .repository_stock_unit_items
                     .find { |item| item.data == repository_stock_unit_item.data }
      end
    value_snapshot.assign_attributes(
      repository_cell: cell_snapshot,
      repository_stock_unit_item: stock_unit_item,
      created_at: created_at,
      updated_at: updated_at
    )
    value_snapshot.save!
  end

  def data
    amount
  end

  def self.new_with_payload(payload, attributes)
    if payload[:amount].present?
      value = new(attributes)
      value.amount = payload[:amount]
      value.low_stock_threshold = payload[:low_stock_threshold]
      value.repository_stock_unit_item = value.repository_cell
                                              .repository_column
                                              .repository_stock_unit_items
                                              .find_by(id: payload['unit_item_id'])
      value
    else
      raise ActiveRecord::RecordInvalid, 'Missing amount value'
    end
  end

  def self.import_from_text(text, attributes, _options = {})
    digit, unit = text.match(/(^\d*\.?\d*)(\D*)/).captures
    digit.strip!
    unit.strip!
    return nil if digit.blank?

    value = new(attributes.merge(amount: BigDecimal(digit)))
    return value if unit.blank?

    column = attributes.dig(:repository_cell_attributes, :repository_column)
    stock_unit_item = column.repository_stock_unit_items.find { |item| item.data == unit }

    if stock_unit_item.blank?
      stock_unit_item = column.repository_stock_unit_items.new(data: unit,
                                                               created_by: value.created_by,
                                                               last_modified_by: value.last_modified_by)

      return value unless stock_unit_item.save
    end

    value.repository_stock_unit_item = stock_unit_item
    value
  rescue ArgumentError
    nil
  end

  alias export_formatted formatted

  private

  def update_consumption_stock_units
    repository_cell.repository_row
                   .my_module_repository_rows
                   .update_all(repository_stock_unit_item_id: repository_stock_unit_item_id)
  end

  def send_low_stock_notification
    LowStockNotification.send_notifications({ repository_row_id: repository_cell.repository_row_id })
  end
end
