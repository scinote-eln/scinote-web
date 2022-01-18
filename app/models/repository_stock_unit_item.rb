# frozen_string_literal: true

class RepositoryStockUnitItem < ApplicationRecord
  DEFAULT_UNITS = %i(L mL uL g mg ug M mM)
  belongs_to :repository_column, inverse_of: :repository_checklist_items
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User',
             inverse_of: :created_repository_checklist_types
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User',
             inverse_of: :modified_repository_checklist_types

  validate :validate_per_column_limit
  validates :data, presence: true,
                   uniqueness: { scope: :repository_column_id },
                   length: { maximum: Constants::NAME_MAX_LENGTH }

  private

  def validate_per_column_limit
    if repository_column &&
       repository_column.repository_stock_unit_items.size > Constants::REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN
      errors.add(:base, :per_column_limit)
    end
  end
end
