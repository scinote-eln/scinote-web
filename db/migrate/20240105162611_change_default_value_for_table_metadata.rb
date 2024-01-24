# frozen_string_literal: true

# rubocop:disable Rails/SkipsModelValidations
class ChangeDefaultValueForTableMetadata < ActiveRecord::Migration[7.0]
  DEFAULT_METADATA = {}.freeze

  def up
    change_column_default :tables, :metadata, from: nil, to: DEFAULT_METADATA

    Table.where(metadata: nil).update_all("metadata = '#{DEFAULT_METADATA}'")
  end

  def down
    change_column_default :tables, :metadata, from: DEFAULT_METADATA, to: nil

    Table.where(metadata: DEFAULT_METADATA).update_all(metadata: nil)
  end
end
# rubocop:enable Rails/SkipsModelValidations
