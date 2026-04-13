# frozen_string_literal: true

class RepopulateUserSettings < ActiveRecord::Migration[7.2]
  TABLE_STATE_KEY_MAP =
    {
      'label_templates_active_table_state' => 'LabelTemplates_active_state',
      'label_templates_archived_table_state' => 'LabelTemplates_archived_state',
      'experiments_active_table_state' => 'ExperimentList_active_state',
      'experiments_archived_table_state' => 'ExperimentList_archived_state',
      'my_modules_active_table_state' => 'MyModuleList_active_state',
      'my_modules_archived_table_state' => 'MyModuleList_archived_state',
      'projects_active_table_state' => 'ProjectList_active_state',
      'projects_archived_table_state' => 'ProjectList_archived_state',
      'protocol_templates_active_table_state' => 'ProtocolTemplates_active_state',
      'protocol_templates_archived_table_state' => 'ProtocolTemplates_archived_state',
      'forms_active_table_state' => 'FormsTable_active_state',
      'forms_archived_table_state' => 'FormsTable_archived_state',
      'report_templates_active_table_state' => 'ReportTemplates_active_state',
      'report_templates_archived_table_state' => 'ReportTemplates_archived_state',
      'repositories_active_table_state' => 'Repositories_active_state',
      'repositories_archived_table_state' => 'Repositories_archived_state',
      'storage_locations_active_table_state' => 'StorageLocationsTable_active_state',
      'storage_locations_container_active_table_state' => 'StorageLocationsContainer_active_state',
      'storage_locations_container_grid_active_table_state' => 'StorageLocationsContainerGrid_active_state',
      'tags_index_active_table_state' => 'TagsIndexTable_active_state',
      'user_groups_active_table_state' => 'UserGroups_active_state',
      'user_group_active_table_state' => 'UserGroup_active_state'
    }.freeze

  NAVIGATOR_STATE_KEY = 'navigator_state'
  NAVIGATOR_COLLAPSED_KEY = 'navigator_collapsed'
  NAVIGATOR_WIDTH_KEY = 'navigator_width'

  class MigrationUserSetting < ActiveRecord::Base
    self.table_name = 'user_settings'
  end

  def up
    MigrationUserSetting.reset_column_information
    User.reset_column_information

    User.find_each do |user|
      current_settings = (user.settings || {}).dup

      MigrationUserSetting.where(user_id: user.id).find_each do |setting|
        if setting.key == NAVIGATOR_STATE_KEY && setting.value.is_a?(Hash)
          current_settings[NAVIGATOR_COLLAPSED_KEY] = setting.value['collapsed'] || false
          current_settings[NAVIGATOR_WIDTH_KEY] = setting.value['width']
          next
        end

        target_key = TABLE_STATE_KEY_MAP[setting.key] || setting.key
        current_settings[target_key] = setting.value
      end

      # rubocop:disable Rails/SkipsModelValidations
      user.update_column(:settings, current_settings)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def down; end
end
