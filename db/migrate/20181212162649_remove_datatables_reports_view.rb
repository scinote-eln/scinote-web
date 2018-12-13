# frozen_string_literal: true

class RemoveDatatablesReportsView < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Base.connection.execute(
      'DROP MATERIALIZED VIEW IF EXISTS datatables_reports'
    )
  end
end
