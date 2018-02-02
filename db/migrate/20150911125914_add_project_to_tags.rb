class AddProjectToTags < ActiveRecord::Migration[4.2]
  def change
    # Add project ID reference, make it nullable at first
    add_column :tags, :project_id, :integer, { null: true }
    add_foreign_key :tags, :projects

    # Clone tags for each project, just to make sure not a single tag has
    # null project_id
    all_tags = Tag.all
    all_tags.each do |tag|
      Project.all.each do |project|
        new_tag = Tag.create(
          name: tag.name,
          color: tag.color,
          project: project
        )

        # Okay, add all my_module-tag references
        tag.my_module_tags.each do |mmt|
          MyModuleTag.create(
            my_module: mmt.my_module,
            tag: new_tag)
        end
      end
    end

    # Okay, clear all tags that still have nil project reference
    Tag.where(project_id: nil).destroy_all

    # Make project ID not null
    change_column_null :tags, :project_id, false
  end
end
