# frozen_string_literal: true

class CreateUserSettings < ActiveRecord::Migration[7.2]
  TABLE_STATE_KEY_MAP = {
    'LabelTemplates_active_state' => 'label_templates_active_table_state',
    'LabelTemplates_archived_state' => 'label_templates_archived_table_state',
    'ExperimentList_active_state' => 'experiments_active_table_state',
    'ExperimentList_archived_state' => 'experiments_archived_table_state',
    'MyModuleList_active_state' => 'my_modules_active_table_state',
    'MyModuleList_archived_state' => 'my_modules_archived_table_state',
    'ProjectList_active_state' => 'projects_active_table_state',
    'ProjectList_archived_state' => 'projects_archived_table_state',
    'ProtocolTemplates_active_state' => 'protocol_templates_active_table_state',
    'ProtocolTemplates_archived_state' => 'protocol_templates_archived_table_state',
    'FormsTable_active_state' => 'forms_active_table_state',
    'FormsTable_archived_state' => 'forms_archived_table_state',
    'ReportTemplates_active_state' => 'report_templates_active_table_state',
    'ReportTemplates_archived_state' => 'report_templates_archived_table_state',
    'Repositories_active_state' => 'repositories_active_table_state',
    'Repositories_archived_state' => 'repositories_archived_table_state',
    'StorageLocationsTable_active_state' => 'storage_locations_active_table_state',
    'StorageLocationsContainer_active_state' => 'storage_locations_container_active_table_state',
    'StorageLocationsContainerGrid_active_state' => 'storage_locations_container_grid_active_table_state',
    'TagsIndexTable_active_state' => 'tags_index_active_table_state',
    'UserGroups_active_state' => 'user_groups_active_table_state',
    'UserGroup_active_state' => 'user_group_active_table_state'
  }.freeze

  def change
    create_table :user_settings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false
      t.json :value, null: false

      t.timestamps
    end

    User.find_each do |user|
      current_settings = user.settings

      TABLE_STATE_KEY_MAP.each do |key, new_key|
        next unless user.settings[key]

        user.user_settings.create!(
          key: new_key,
          value: user.settings[key]
        )

        current_settings.delete(key)
      end

      # rubocop:disable Rails/SkipsModelValidations
      user.update_column(:settings, current_settings)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
