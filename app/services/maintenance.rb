class Maintenance
  def self.show_all_tables_count
    table_with_count = []
    ActiveRecord::Base.connection.tables.each do |table|
      next if %w(ar_internal_metadata
                 schema_migrations
                 delayed_jobs
                 scinote_enterprise_electronic_signatures
                 settings
                 versions
                 scinote_ai_manuscripts
                 billing_addons
                 billing_accounts
                 billing_plans
                 billing_subscriptions
                 billing_subscription_addons
                 scinote_core_gamification_scores).include?(table)
      table_with_count << [name: table,
                           count: table.singularize.camelize.constantize.count]
    end
    table_with_count
  end
end
