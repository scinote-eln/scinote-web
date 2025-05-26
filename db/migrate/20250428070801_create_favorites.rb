# frozen_string_literal: true

class CreateFavorites < ActiveRecord::Migration[7.0]
  STATE_NAMES = %w(ProjectList_active_state ProjectList_archived_state ExperimentList_active_state
                   ExperimentList_archived_state MyModuleList_active_state MyModuleList_archived_state).freeze
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :item, polymorphic: true, null: false

      t.timestamps
    end

    add_index(
      :favorites,
      %i(user_id team_id item_id item_type),
      unique: true,
      name: :index_favorites_on_user_and_item_and_team
    )

    reversible do |dir|
      dir.up do
        User.find_each do |user|
          update = false
          STATE_NAMES.each do |state_name|
            state = user.settings.dig(state_name, 'columnsState')
            next if state.blank?

            update = true

            # get number of pinned columns
            pinned_items_count = state.count { |el| el['pinned'].present? }

            # update position of columns if they are not pinned
            state.each do |el|
              el['position'] += 1 if el['pinned'].blank? && el['position'].present?
            end

            # create new state of favorite column
            new_element = {
              colId: 'favorite',
              hide: false,
              pinned: nil
            }

            # add only position if other columns have positions. Position only get columns for which user at least once change settings
            new_element[:position] = pinned_items_count if state.dig(0, 'position').present?
            state.insert(pinned_items_count, new_element)
          end
          user.save! if update
        end
      end

      dir.down do
        User.find_each do |user|
          update = false
          STATE_NAMES.each do |state_name|
            state = user.settings.dig(state_name, 'columnsState')
            next if state.blank?

            update = true

            favorite = state.find { |el| el['colId'] == 'favorite' }

            next unless favorite

            state.reject! { |el| el['colId'] == 'favorite' }

            next if favorite['position'].blank?

            state.each do |el|
              el['position'] -= 1 if el['position'].present? && el['position'] > favorite['position']
            end
          end
          user.save! if update
        end
      end
    end
  end
end
