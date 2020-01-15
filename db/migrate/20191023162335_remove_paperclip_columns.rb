# frozen_string_literal: true

class RemovePaperclipColumns < ActiveRecord::Migration[6.0]
  def up
    remove_columns :assets,
                   :file_file_name,
                   :file_content_type,
                   :file_file_size,
                   :file_updated_at if column_exists? :assets, :file_file_name
    remove_columns :assets, :file_present 
    remove_columns :experiments,
                   :workflowimg_file_name,
                   :workflowimg_content_type,
                   :workflowimg_file_size,
                   :workflowimg_updated_at if column_exists? :experiments, :workflowimg_file_name
    remove_columns :temp_files,
                   :file_file_name,
                   :file_content_type,
                   :file_file_size,
                   :file_updated_at if column_exists? :temp_files, :file_file_name
    remove_columns :tiny_mce_assets,
                   :image_file_name,
                   :image_content_type,
                   :image_file_size,
                   :image_updated_at if column_exists? :tiny_mce_assets, :image_file_name
    remove_columns :users,
                   :avatar_file_name,
                   :avatar_content_type,
                   :avatar_file_size,
                   :avatar_updated_at if column_exists? :users, :avatar_file_name
    remove_columns :zip_exports,
                   :zip_file_file_name,
                   :zip_file_content_type,
                   :zip_file_file_size,
                   :zip_file_updated_at if column_exists? :zip_exports, :zip_file_file_name
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
