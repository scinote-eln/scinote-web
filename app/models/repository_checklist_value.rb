# frozen_string_literal: true

class RepositoryChecklistValue < ApplicationRecord
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User',
                          inverse_of: :created_repository_checklist_values
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User',
                                inverse_of: :modified_repository_checklist_values
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  has_many :repository_checklist_items_values, dependent: :destroy
  has_many :repository_checklist_items, -> { order('data ASC') },
           through: :repository_checklist_items_values,
           dependent: :destroy
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true
  validates :repository_checklist_items, presence: true

  SORTABLE_COLUMN_NAME = 'repository_checklist_items.data'
  EXTRA_SORTABLE_VALUE_INCLUDE = :repository_checklist_items
  EXTRA_PRELOAD_INCLUDE = :repository_checklist_items

  def formatted(separator: ' | ')
    repository_checklist_items.pluck(:data).join(separator)
  end

  def export_formatted
    formatted(separator: repository_cell.repository_column.delimiter_char)
  end

  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    items_join_alias = "#{join_alias}_checklist_items"
    repository_rows =
      repository_rows
      .joins(
        "LEFT OUTER JOIN \"repository_checklist_items_values\" AS \"#{join_alias}_checklist_items_values\" " \
        "ON  \"#{join_alias}_checklist_items_values\".\"repository_checklist_value_id\" = \"#{join_alias}\".\"id\""
      )
      .joins(
        "LEFT OUTER JOIN \"repository_checklist_items\" AS \"#{items_join_alias}\" " \
        "ON  \"#{join_alias}_checklist_items_values\".\"repository_checklist_item_id\" = \"#{items_join_alias}\".\"id\""
      )

    case filter_element.operator
    when 'any_of'
      repository_rows
        .where("#{items_join_alias}.id = ANY(ARRAY[?]::bigint[])", filter_element.parameters['item_ids'])
    when 'all_of'
      repository_rows
        .having("ARRAY_AGG(#{items_join_alias}.id ORDER BY #{items_join_alias}.id) @> ARRAY[?]::bigint[]",
                filter_element.parameters['item_ids'].sort)
        .group(:id)
    when 'none_of'
      repository_rows
        .having("NOT ARRAY_AGG(#{items_join_alias}.id) && ARRAY[?]::bigint[]", filter_element.parameters['item_ids'])
        .group(:id)
    else
      raise ArgumentError, 'Wrong operator for RepositoryChecklistValue!'
    end
  end

  def data
    repository_checklist_items.map { |i| { value: i.id, label: i.data } }
  end

  def data_different?(new_data)
    if new_data.is_a?(String)
      JSON.parse(new_data) != repository_checklist_items.pluck(:id)
    else
      new_data != repository_checklist_items.pluck(:id)
    end
  end

  def update_data!(new_data, user)
    item_ids = new_data.is_a?(String) ? JSON.parse(new_data) : new_data
    return destroy! if item_ids.blank?

    # update!(repository_checklist_items: repository_cell.repository_column.repository_checklist_items.where(id: item_ids), last_modified_by: user)

    self.repository_checklist_items = repository_cell.repository_column
                                                     .repository_checklist_items
                                                     .where(id: item_ids)
    self.last_modified_by = user
    save!
  end

  def snapshot!(cell_snapshot)
    value_snapshot = dup
    item_values = repository_checklist_items.pluck(:data)
    checklist_items_snapshot = cell_snapshot.repository_column
                                            .repository_checklist_items
                                            .select { |snapshot_item| item_values.include?(snapshot_item.data) }

    value_snapshot.assign_attributes(
      repository_cell: cell_snapshot,
      repository_checklist_items: checklist_items_snapshot,
      created_at: created_at,
      updated_at: updated_at
    )
    value_snapshot.save!
  end

  def self.new_with_payload(payload, attributes)
    item_ids = payload.is_a?(String) ? JSON.parse(payload) : payload
    value = new(attributes)
    value.repository_checklist_items = value.repository_cell
                                            .repository_column
                                            .repository_checklist_items
                                            .where(id: item_ids)
    value
  end

  def self.import_from_text(text, attributes, _options = {})
    return nil if text.blank?

    value = new(attributes)
    column = attributes.dig(:repository_cell_attributes, :repository_column)
    RepositoryImportParser::Util.split_by_delimiter(text: text, delimiter: column.delimiter_char).each do |item_text|
      checklist_item = column.repository_checklist_items.find { |item| item.data == item_text }

      if checklist_item.blank?
        checklist_item = column.repository_checklist_items.new(data: item_text,
                                                               created_by: value.created_by,
                                                               last_modified_by: value.last_modified_by)

        return nil unless checklist_item.save
      end

      value.repository_checklist_items << checklist_item
    end

    value
  end
end
