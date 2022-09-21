# frozen_string_literal: true

class AddReportCodeIndex < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_reports_on_report_code ON "\
      "reports using gin (('RP'::text || id) gin_trgm_ops);"
    )
  end

  def down
    remove_index :reports, name: 'index_reports_on_report_code'
  end
end
