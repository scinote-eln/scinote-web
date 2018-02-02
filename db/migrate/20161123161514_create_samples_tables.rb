class CreateSamplesTables < ActiveRecord::Migration[4.2]
  def change
    create_table :samples_tables do |t|
      t.jsonb :status, null: false,
              default: SampleDatatable::SAMPLES_TABLE_DEFAULT_STATE
      # Foreign keys
      t.references :user, null: false
      t.references :team, null: false

      t.timestamps null: false
    end
    add_index :samples_tables, :user_id
    add_index :samples_tables, :team_id

    User.find_each do |user|
      next unless user.teams
      user.teams.find_each do |team|
        team_status = SampleDatatable::SAMPLES_TABLE_DEFAULT_STATE.deep_dup
        next unless team.custom_fields
        team.custom_fields.each_with_index do |_, index|
          team_status['columns'] << { 'visible' => true,
                                      'search' => {
                                        'search' => '',
                                        'smart' => true,
                                        'regex' => false,
                                        'caseInsensitive' => true
                                      } }
          team_status['ColReorder'] << (7 + index)
        end

        SamplesTable.create(user: user, team: team, status: team_status)
      end
    end
  end
end
