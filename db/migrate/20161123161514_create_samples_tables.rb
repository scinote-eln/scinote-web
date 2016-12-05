class CreateSamplesTables < ActiveRecord::Migration
  @@def_state = { 'time' => 0,
                  'start' => 0,
                  'length' => 10,
                  'order' => [[2, 'desc']],
                  'search' => { 'search' => '',
                                'smart' => true,
                                'regex' => false,
                                'caseInsensitive' => true },
                  'columns' => [{ 'visible' => true,
                                  'search' => { 'search' => '',
                                                'smart' => true,
                                                'regex' => false,
                                                'caseInsensitive' => true } },
                                { 'visible' => true,
                                  'search' => { 'search' => '',
                                                'smart' => true,
                                                'regex' => false,
                                                'caseInsensitive' => true } },
                                { 'visible' => true,
                                  'search' => { 'search' => '',
                                                'smart' => true,
                                                'regex' => false,
                                                'caseInsensitive' => true } },
                                { 'visible' => true,
                                  'search' => { 'search' => '',
                                                'smart' => true,
                                                'regex' => false,
                                                'caseInsensitive' => true } },
                                { 'visible' => true,
                                  'search' => { 'search' => '',
                                                'smart' => true,
                                                'regex' => false,
                                                'caseInsensitive' => true } },
                                { 'visible' => true,
                                  'search' => { 'search' => '',
                                                'smart' => true,
                                                'regex' => false,
                                                'caseInsensitive' => true } },
                                { 'visible' => true,
                                  'search' => { 'search' => '',
                                                'smart' => true,
                                                'regex' => false,
                                                'caseInsensitive' => true } }],
                  'ColReorder' => [0, 1, 2, 3, 4, 5, 6] }

  def change
    create_table :samples_tables do |t|
      t.jsonb :status, null: false, default: @@def_state
      # Foreign keys
      t.references :user, null: false
      t.references :organization, null: false

      t.timestamps null: false
    end
    add_index :samples_tables, :user_id
    add_index :samples_tables, :organization_id

    User.find_each do |user|
      next unless user.organizations
      user.organizations.find_each do |org|
        org_status = @@def_state.deep_dup
        next unless org.custom_fields
        org.custom_fields.each_with_index do |_, index|
          org_status['columns'] << { 'visible' => true,
                                     'search' => { 'search' => '',
                                                   'smart' => true,
                                                   'regex' => false,
                                                   'caseInsensitive' => true } }
          org_status['ColReorder'] << (7 + index)
        end

        SamplesTable.create(user: user, organization: org, status: org_status)
      end
    end
  end
end
