# frozen_string_literal: true

module ReminderRepositoryCellJoinable
  extend ActiveSupport::Concern

  included do
    def self.reminder_repository_cells_scope(relation, user)
      relation.joins( # datetime reminders
        'LEFT OUTER JOIN "repository_date_time_values" ON '\
        '"repository_date_time_values"."id" = "repository_cells"."value_id" AND '\
        '"repository_cells"."value_type" = \'RepositoryDateTimeValueBase\' '\
        'AND repository_columns.metadata ? \'reminder_delta\' AND '\
        '(repository_date_time_values.data - NOW()) <= '\
        '(repository_columns.metadata -> \'reminder_delta\')::int * interval \'1 sec\''
      ).joins( # stock reminders
        'LEFT OUTER JOIN "repository_stock_values" ON "repository_stock_values"."id" = "repository_cells"."value_id" AND '\
        '"repository_cells"."value_type" = \'RepositoryStockValue\' AND '\
        'repository_stock_values.amount <= repository_stock_values.low_stock_threshold'
      ).joins(
        'LEFT OUTER JOIN "hidden_repository_cell_reminders" ON '\
        '"repository_cells"."id" = "hidden_repository_cell_reminders"."repository_cell_id" AND '\
        '"hidden_repository_cell_reminders"."user_id" = ' + user.id.to_s
      ).where(
        'hidden_repository_cell_reminders.id IS NULL AND '\
        'repository_date_time_values.id IS NOT NULL OR repository_stock_values.id IS NOT NULL'
      )
    end
  end
end
