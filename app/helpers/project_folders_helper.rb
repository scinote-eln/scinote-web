# frozen_string_literal: true

module ProjectFoldersHelper
  def items_label(items)
    if items == 'projects'
      I18n.t('projects.index.modal_move_folder.items.projects')
    elsif items == 'folders'
      I18n.t('projects.index.modal_move_folder.items.folders')
    else
      I18n.t('projects.index.modal_move_folder.items.projects_and_folders')
    end
  end

  def tree_ordered_parent_folders(current_folder)
    folders = current_folder&.parent_folders
    return unless folders

    ordered_folders = [current_folder]
    folders.each do
      folder = folders.find { |f| f.id == ordered_folders.last.parent_folder_id }
      break unless folder

      ordered_folders << folder
    end

    ordered_folders.reverse
  end
end
