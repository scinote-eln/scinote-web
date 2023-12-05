# frozen_string_literal: true

class RepositoryLedgerRecord < ApplicationRecord
  auto_strip_attributes :comment

  belongs_to :repository_stock_value
  belongs_to :reference, polymorphic: true
  belongs_to :user
  belongs_to :repository,
             (lambda do |repository_ledger_record|
               repository_ledger_record.reference_type == 'RepositoryBase' ? self : none
             end),
             optional: true, foreign_key: :reference_id, inverse_of: :repository_ledger_records
  belongs_to :my_module_repository_row,
             (lambda do |repository_ledger_record|
               repository_ledger_record.reference_type == 'MyModuleRepositoryRow' ? self : none
             end),
             optional: true, foreign_key: :reference_id, inverse_of: :repository_ledger_records
  has_one :repository_row, through: :repository_stock_value

  validate :my_module_references_present?, if: -> { reference.is_a?(MyModuleRepositoryRow) }

  private

  def my_module_references_present?
    return if my_module_references.present? &&
              my_module_references['my_module_id'].is_a?(Integer) &&
              my_module_references['experiment_id'].is_a?(Integer) &&
              my_module_references['project_id'].is_a?(Integer) &&
              my_module_references['team_id'].is_a?(Integer)

    errors.add(:base, I18n.t('repository_ledger_records.errors.my_module_references_missing'))
  end
end
