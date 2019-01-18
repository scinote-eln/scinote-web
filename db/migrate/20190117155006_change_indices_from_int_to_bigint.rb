class ChangeIndicesFromIntToBigint < ActiveRecord::Migration[5.1]
  def up
  # The request for this migration comes from a ticket SCI-2936,
  # the request is to change all of the indices (primary and foreign keys) to bigint type
  # 
  # What it basically does is finds all of the indices of type int and changes them to bigint
  # A minor complication/restraint is, postgres prohibits changes of the fields
  # that are used in postgres view, so firstly we drop all of (user defined) views
  # then change the column types and recreate vies afterwards.


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
    keys = execute(sql)

    if keys.any?
      # get all user defined views
      user_viewes = execute(
        "select  *  from pg_views where schemaname = any (current_schemas(false))"
                           )

      # drop all existing views
      user_viewes.each do |user_view|
        execute("drop view #{user_view['viewname']}")
      end

      # change all keys
      keys.each do |key|
        change_column key['table_name'], key['column_name'], :bigint
      end

      # recreate user defined views
      user_viewes.each do |user_view|
        execute("create view #{user_view['viewname']} as #{user_view['definition']}")
      end
    end
  end

  def down
    # Bad, bad things can happen if we reverse this migration, so we'll 
    # simply skip it
  end
end
