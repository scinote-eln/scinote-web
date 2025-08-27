# frozen_string_literal: true

class MergeDuplicatedTags < ActiveRecord::Migration[7.2]
  TAG_ACTIVITY_TYPES = [64, 65, 66, 108, 109].freeze

  def up
    tag_duplications = Tag.group(:name, :color, :team_id).having('COUNT(*) > 1').select(:name, :color, :team_id)
    tag_duplications.each do |tag_duplication|
      duplicated_tags_group = Tag.where(name: tag_duplication.name, color: tag_duplication.color, team_id: tag_duplication.team_id).order(:created_at)
      duplicated_tags_group.lock!
      tag_to_keep = duplicated_tags_group.first
      tags_to_remove = duplicated_tags_group.offset(1)

      execute <<~SQL.squish
        UPDATE activities
        SET values = jsonb_set(values, '{"message_items", "tag", "id"}', '#{tag_to_keep.id}'::jsonb)
        WHERE type_of IN (#{TAG_ACTIVITY_TYPES.join(',')}) AND
        (values #>> '{"message_items", "tag", "id" }')::bigint IN (#{tags_to_remove.select(:id).to_sql})
      SQL

      Tagging.where(tag_id: tags_to_remove.select(:id)).find_each do |tagging|
        if tagging.taggable.taggings.exists?(tag: tag_to_keep)
          tagging.delete
        else
          tagging.update!(tag_id: tag_to_keep.id)
        end
      end

      tags_to_remove.delete_all
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
