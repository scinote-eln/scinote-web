# frozen_string_literal: true

# The samples tables were dropped from the schema, but Tasks::SamplesToRepositoryMigrationService reads them with
# raw SQL. This context recreates them inside the per-example transaction (PostgreSQL DDL is transactional, so
# everything is rolled back at the end of the example) and offers small insert helpers.
shared_context 'legacy samples tables' do
  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE sample_types (id serial PRIMARY KEY, name varchar, team_id bigint,
                                 created_by_id bigint, last_modified_by_id bigint);
      CREATE TABLE sample_groups (id serial PRIMARY KEY, name varchar, color varchar, team_id bigint,
                                  created_by_id bigint, last_modified_by_id bigint);
      CREATE TABLE samples (id serial PRIMARY KEY, name varchar, user_id bigint, last_modified_by_id bigint,
                            team_id bigint, sample_type_id bigint, sample_group_id bigint,
                            created_at timestamp, updated_at timestamp);
      CREATE TABLE custom_fields (id serial PRIMARY KEY, name varchar, team_id bigint, user_id bigint,
                                  created_at timestamp, updated_at timestamp);
      CREATE TABLE sample_custom_fields (id serial PRIMARY KEY, sample_id bigint, custom_field_id bigint,
                                         value varchar, created_at timestamp, updated_at timestamp);
      CREATE TABLE sample_my_modules (id serial PRIMARY KEY, sample_id bigint, my_module_id bigint,
                                      assigned_by_id bigint);
    SQL
  end

  # Inserts a row and returns its id. Values are quoted by the connection.
  def insert_legacy(table, attributes)
    conn = ActiveRecord::Base.connection
    columns = attributes.keys.join(', ')
    values = attributes.values.map { |v| conn.quote(v) }.join(', ')
    conn.select_value("INSERT INTO #{table} (#{columns}) VALUES (#{values}) RETURNING id")
  end
end

# The migration code calls Time#to_s(:db), which Rails 7.1+ no longer supports (ArgumentError). This context hands the
# code a Time subclass that still understands the :db format so the remaining logic can be exercised. The plain,
# unpatched behaviour is covered by the pending 'bug' examples.
shared_context 'clock supporting to_s(:db)' do
  before do
    clock_class = Class.new(Time) do
      def to_s(format = nil)
        format == :db ? strftime('%Y-%m-%d %H:%M:%S') : super()
      end
    end
    allow(Time).to receive(:now).and_return(clock_class.at(Time.now.to_f))
  end
end
