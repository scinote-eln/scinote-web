# frozen_string_literal: true

module ReminderRepositoryCellJoinable
  extend ActiveSupport::Concern

  included do
    def self.reminder_repository_cells_scope(relation, user)
      relation.joins(
        'INNER JOIN repository_columns repository_reminder_columns ON ' \
        'repository_reminder_columns.id = repository_cells.repository_column_id'
      ).joins( # datetime reminders
        'LEFT OUTER JOIN "repository_date_time_values" ON '\
        '"repository_date_time_values"."id" = "repository_cells"."value_id" AND '\
        '"repository_cells"."value_type" = \'RepositoryDateTimeValueBase\' '\
        'AND repository_reminder_columns.metadata ->> \'reminder_value\' <> \'\' AND '\
        '(repository_date_time_values.data - NOW()) <= '\
        '(repository_reminder_columns.metadata ->> \'reminder_value\')::int * ' \
        '(repository_reminder_columns.metadata ->> \'reminder_unit\')::int * interval \'1 sec\''
      ).joins( # stock reminders
        'LEFT OUTER JOIN "repository_stock_values" ON '\
        '"repository_cells"."value_type" = \'RepositoryStockValue\' AND '\
        '"repository_stock_values"."id" = "repository_cells"."value_id" AND '\
        '(repository_stock_values.amount <= repository_stock_values.low_stock_threshold OR '\
        ' repository_stock_values.amount <= 0)'
      ).joins(
        'LEFT OUTER JOIN "hidden_repository_cell_reminders" ON '\
        '"repository_cells"."id" = "hidden_repository_cell_reminders"."repository_cell_id" AND '\
        '"hidden_repository_cell_reminders"."user_id" = ' + user.id.to_s
      ).where(
        'hidden_repository_cell_reminders.id IS NULL AND '\
        '(repository_date_time_values.id IS NOT NULL OR repository_stock_values.id IS NOT NULL)'
      )
    end

    def self.stock_reminder_repository_cells_scope(relation, user)
      relation.joins( # stock reminders
        'LEFT OUTER JOIN "repository_stock_values" ON ' \
        '"repository_cells"."value_type" = \'RepositoryStockValue\' AND ' \
        '"repository_stock_values"."id" = "repository_cells"."value_id" AND ' \
        '(repository_stock_values.amount <= repository_stock_values.low_stock_threshold OR ' \
        'repository_stock_values.amount <= 0)'
      ).joins(
        'LEFT OUTER JOIN "hidden_repository_cell_reminders" ON ' \
        '"repository_cells"."id" = "hidden_repository_cell_reminders"."repository_cell_id" AND ' \
        '"hidden_repository_cell_reminders"."user_id" = ' + user.id.to_s
      ).where(
        'hidden_repository_cell_reminders.id IS NULL AND repository_stock_values.id IS NOT NULL'
      )
    end

    def self.date_time_reminder_repository_cells_scope(relation, user)
      relation.joins( # datetime reminders
        'LEFT OUTER JOIN "repository_date_time_values" ON ' \
        '"repository_date_time_values"."id" = "repository_cells"."value_id" AND ' \
        '"repository_cells"."value_type" = \'RepositoryDateTimeValueBase\' ' \
        'AND repository_columns.metadata ->> \'reminder_value\' <> \'\' AND ' \
        '(repository_date_time_values.data - NOW()) <= ' \
        '(repository_columns.metadata ->> \'reminder_value\')::int * ' \
        '(repository_columns.metadata ->> \'reminder_unit\')::int * interval \'1 sec\''
      ).joins(
        'LEFT OUTER JOIN "hidden_repository_cell_reminders" ON ' \
        '"repository_cells"."id" = "hidden_repository_cell_reminders"."repository_cell_id" AND ' \
        '"hidden_repository_cell_reminders"."user_id" = ' + user.id.to_s
      ).where(
        'hidden_repository_cell_reminders.id IS NULL AND repository_date_time_values.id IS NOT NULL'
      )
    end
  end
end
