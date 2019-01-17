class ChangeIndicesFromIntToBigint < ActiveRecord::Migration[5.1]
  def up
  # find primary and foreign keys of type integer throughout the database
    sql = <<-EOM
      select tc.table_schema, tc.table_name, kc.column_name, ic.data_type
      from information_schema.table_constraints tc
        join information_schema.key_column_usage kc 
          on kc.table_name = tc.table_name and kc.table_schema = tc.table_schema and kc.constraint_name = tc.constraint_name
        join information_schema.columns ic
          on ic.table_schema = tc.table_schema and ic.table_name=tc.table_name and ic.column_name = kc.column_name 
      where (tc.constraint_type = 'PRIMARY KEY' OR tc.constraint_type = 'FOREIGN KEY')
        and kc.ordinal_position is not null
        and ic.data_type = 'integer'
      order by tc.table_schema,
               tc.table_name,
               kc.position_in_unique_constraint;
    EOM

    # get all user defined views
    user_viewes = ActiveRecord::Base.connection.execute(
      "select  *  from pg_views where schemaname = any (current_schemas(false))"
      )

    # drop all existing views
    user_viewes.each do |user_view|
      ActiveRecord::Base.connection.execute("drop view #{user_view['viewname']}")
    end

    keys = ActiveRecord::Base.connection.execute(sql)

    # change all keys
    keys.each do |key|
      change_column key['table_name'], key['column_name'], :bigint
    end

    # recreate user defined views
    user_viewes.each do |user_view|
      ActiveRecord::Base.connection.execute("create view #{user_view['viewname']} as #{user_view['definition']}")
    end
  end
end
